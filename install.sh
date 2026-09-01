#!/usr/bin/env bash
# Deterministic installer for the sitemap-parser Claude skill.
# 1. Creates a Python venv inside the repo
# 2. Installs the pinned dependencies from requirements.txt
# 3. Symlinks this repo into ~/.claude/skills/sitemap-parser
# 4. Probes a live site to verify, distinguishing a broken install
#    from an unreachable network
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd -P)"
SKILL_LINK="$HOME/.claude/skills/sitemap-parser"

echo "==> sitemap-parser installer"
echo "    repo:      $REPO_DIR"
echo "    skill dir: $SKILL_LINK"

# 1. Verify python3
if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 not found in PATH" >&2
    exit 1
fi
echo "==> Found python3: $(command -v python3) ($(python3 --version))"

# 2. Create venv and install the library
if [ -d "$REPO_DIR/.venv" ]; then
    echo "==> Reusing existing venv at $REPO_DIR/.venv"
else
    echo "==> Creating venv at $REPO_DIR/.venv"
    python3 -m venv "$REPO_DIR/.venv"
fi
echo "==> Upgrading pip"
"$REPO_DIR/.venv/bin/pip" install --quiet --upgrade pip
echo "==> Installing dependencies from requirements.txt"
"$REPO_DIR/.venv/bin/pip" install --quiet -r "$REPO_DIR/requirements.txt"

# 3. Symlink into Claude's user-level skills folder
mkdir -p "$HOME/.claude/skills"
if [ -L "$SKILL_LINK" ]; then
    echo "==> Replacing existing symlink at $SKILL_LINK"
    rm "$SKILL_LINK"
elif [ -e "$SKILL_LINK" ]; then
    echo "Error: $SKILL_LINK exists and is not a symlink. Move or delete it, then re-run." >&2
    exit 1
fi
ln -s "$REPO_DIR" "$SKILL_LINK"
echo "==> Linked $SKILL_LINK -> $REPO_DIR"

# 4. Probe to verify. The probe needs the network, so a failure here is ambiguous
#    between a broken install and an unreachable site. Tell those two apart before
#    failing: only a broken install should stop the installer.
PROBE_URL="${PROBE_URL:-https://tidio.com}"
echo "==> Probing $PROBE_URL (writing to /tmp)"
# A header-only CSV is non-empty, so require at least one data row.
if PROBE_PATH="$("$REPO_DIR/run.sh" "$PROBE_URL" --output /tmp)" \
   && [ -f "$PROBE_PATH" ] && [ "$(wc -l < "$PROBE_PATH")" -gt 1 ]; then
    echo "==> Probe succeeded: $PROBE_PATH"
elif ! "$REPO_DIR/.venv/bin/python3" - "$PROBE_URL" <<'PYEOF'
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
