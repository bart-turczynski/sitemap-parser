#!/usr/bin/env bash
# Deterministic installer for the sitemap-parser Claude skill.
# 1. Creates a Python venv inside the repo
# 2. Installs the pinned dependencies from requirements.txt
# 3. Symlinks the repo's skill/ directory into ~/.claude/skills/sitemap-parser
# 4. Probes a live site to verify, distinguishing a broken install
#    from an unreachable network
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd -P)"
# Only skill/ is linked, never the repository root: the runtime treats whatever it
# links as the skill package, and the root carries .git, .venv and this installer.
SKILL_DIR="$REPO_DIR/skill"
SKILL_LINK="$HOME/.claude/skills/sitemap-parser"

echo "==> sitemap-parser installer"
echo "    repo:       $REPO_DIR"
echo "    skill dir:  $SKILL_DIR"
echo "    skill link: $SKILL_LINK"

# 1. Find a Python new enough for the dependencies.
#    The floor matches what ultimate-sitemap-parser requires. macOS still ships
#    3.9 at /usr/bin/python3, so the first python3 on PATH is not always good
#    enough. Fail with the reason rather than letting pip reject the wheel later.
#    Read the floor from pyproject.toml so it is declared in one place. Parsed
#    with sed, not Python: at this point we have no interpreter we trust.
PYPROJECT="$REPO_DIR/pyproject.toml"
PY_MIN="$(sed -n 's/^[[:space:]]*requires-python[[:space:]]*=[[:space:]]*"[^0-9]*\([0-9][0-9]*\.[0-9][0-9]*\)".*/\1/p' "$PYPROJECT" | head -1)"
if [ -z "$PY_MIN" ]; then
    echo "Error: could not read requires-python from $PYPROJECT." >&2
    echo "       Expected a line like: requires-python = \">=3.10\"" >&2
    exit 1
fi
PY_MIN_MAJOR="${PY_MIN%%.*}"
PY_MIN_MINOR="${PY_MIN#*.}"

# Succeeds when the interpreter in $1 is at least $PY_MIN.
python_ok() {
    "$1" -c "import sys; sys.exit(0 if sys.version_info[:2] >= ($PY_MIN_MAJOR, $PY_MIN_MINOR) else 1)" \
        >/dev/null 2>&1
}

# Print the path of a usable interpreter, or return 1. Prefers a plain python3
# when it qualifies, else the highest versioned python3.x found on PATH. The
# list is discovered, not hard-coded, so a newer Python works without an edit.
find_python() {
    if command -v python3 >/dev/null 2>&1 && python_ok python3; then
        command -v python3
        return 0
    fi
    local found
    found="$(
        IFS=:
        for dir in $PATH; do
            [ -d "$dir" ] || continue
            for exe in "$dir"/python3.[0-9] "$dir"/python3.[0-9][0-9]; do
                [ -x "$exe" ] || continue
                # Sort key first so 3.10 ranks above 3.9 numerically.
                printf '%s %s\n' "${exe##*/python3.}" "$exe"
            done
        # IFS is still ':' for the PATH split above, so give read its own.
        done | sort -k1,1nr -u | while IFS=' ' read -r _minor exe; do
            if python_ok "$exe"; then
                printf '%s\n' "$exe"
                break
            fi
        done
    )"
    [ -n "$found" ] || return 1
    printf '%s\n' "$found"
}

if ! PYTHON="$(find_python)"; then
    echo "Error: no Python $PY_MIN or newer found in PATH." >&2
    if command -v python3 >/dev/null 2>&1; then
        echo "       python3 is $(python3 --version 2>&1) at $(command -v python3)." >&2
    else
        echo "       No python3 found in PATH at all." >&2
    fi
    echo "       ultimate-sitemap-parser requires Python $PY_MIN or newer." >&2
    echo "       Install one (macOS: 'brew install python3') and re-run." >&2
    exit 1
fi
echo "==> Using Python: $PYTHON ($("$PYTHON" --version))"

# 2. Create venv and install the library
VENV_DIR="$REPO_DIR/.venv"
VENV_PY="$VENV_DIR/bin/python3"
if [ -x "$VENV_PY" ] && python_ok "$VENV_PY"; then
    echo "==> Reusing existing venv at $VENV_DIR ($("$VENV_PY" --version))"
elif [ -e "$VENV_DIR" ]; then
    # Left over from a Python older than the floor, or half-built. It holds no
    # source of ours and install.sh rebuilds it, so replacing it is safe.
    echo "==> Existing venv at $VENV_DIR is unusable or older than $PY_MIN; recreating"
    rm -rf "$VENV_DIR"
    "$PYTHON" -m venv "$VENV_DIR"
else
    echo "==> Creating venv at $VENV_DIR"
    "$PYTHON" -m venv "$VENV_DIR"
fi
echo "==> Upgrading pip"
"$VENV_DIR/bin/pip" install --quiet --upgrade pip
echo "==> Installing dependencies from requirements.txt"
"$VENV_DIR/bin/pip" install --quiet -r "$REPO_DIR/requirements.txt"

# 3. Symlink into Claude's user-level skills folder
mkdir -p "$HOME/.claude/skills"
if [ -L "$SKILL_LINK" ]; then
    # Naming the old target matters when it is the repository root: that is the
    # pre-skill/ install, and after a pull it resolves to a directory with no
    # SKILL.md, so the skill has silently stopped loading.
    echo "==> Replacing existing symlink at $SKILL_LINK -> $(readlink "$SKILL_LINK")"
    rm "$SKILL_LINK"
elif [ -e "$SKILL_LINK" ]; then
    echo "Error: $SKILL_LINK exists and is not a symlink. Move or delete it, then re-run." >&2
    exit 1
fi
ln -s "$SKILL_DIR" "$SKILL_LINK"
echo "==> Linked $SKILL_LINK -> $SKILL_DIR"

# 4. Probe to verify. The probe needs the network, so a failure here is ambiguous
#    between a broken install and an unreachable site. Tell those two apart before
#    failing: only a broken install should stop the installer.
PROBE_URL="${PROBE_URL:-https://tidio.com}"
echo "==> Probing $PROBE_URL (writing to /tmp)"
# A header-only CSV is non-empty, so require at least one data row.
if PROBE_PATH="$("$SKILL_DIR/run.sh" "$PROBE_URL" --output /tmp)" \
   && [ -f "$PROBE_PATH" ] && [ "$(wc -l < "$PROBE_PATH")" -gt 1 ]; then
    echo "==> Probe succeeded: $PROBE_PATH"
elif ! "$VENV_PY" - "$PROBE_URL" <<'PYEOF'
import sys, urllib.request
try:
    urllib.request.urlopen(sys.argv[1], timeout=10).read(1)
except Exception:
    sys.exit(1)
PYEOF
then
    echo "Warning: could not reach $PROBE_URL, so the probe was skipped." >&2
    echo "         The venv and symlink are in place. Re-run with PROBE_URL=<site>" >&2
    echo "         set to a reachable site to verify end to end." >&2
else
    echo "Error: $PROBE_URL is reachable but the probe returned no URLs." >&2
    echo "       Either the install is broken, or that site has no sitemap." >&2
    echo "       Check the output above, or retry with PROBE_URL=<site known to" >&2
    echo "       publish a sitemap>." >&2
    exit 1
fi

echo "==> Done. Restart Claude Code so it picks up the new skill."
