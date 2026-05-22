#!/usr/bin/env bash
# Deterministic installer for the sitemap-parser Claude skill.
# 1. Creates a Python venv inside the repo
# 2. Installs ultimate-sitemap-parser into it
# 3. Symlinks this repo into ~/.claude/skills/sitemap-parser
# 4. Runs a probe against tidio.com to verify everything works
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
echo "==> Installing ultimate-sitemap-parser"
"$REPO_DIR/.venv/bin/pip" install --quiet ultimate-sitemap-parser

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

# 4. Probe to verify
echo "==> Probing https://tidio.com (writing to /tmp)"
PROBE_PATH="$("$REPO_DIR/run.sh" https://tidio.com --output /tmp)"
if [ -s "$PROBE_PATH" ]; then
    echo "==> Probe succeeded: $PROBE_PATH"
else
    echo "Error: probe did not produce a file at $PROBE_PATH" >&2
    exit 1
fi

echo "==> Done. Restart Claude Code so it picks up the new skill."
