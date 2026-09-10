#!/usr/bin/env bash
# The skill directory holds only what Claude reads; the CLI and the venv live in
# the repository one level up. pwd -P resolves the ~/.claude/skills symlink
# first, so the parent is the repository even when invoked through the link.
SKILL_DIR="$(cd "$(dirname "$0")" && pwd -P)"
REPO_DIR="$(dirname "$SKILL_DIR")"
if [ -x "$REPO_DIR/.venv/bin/python3" ]; then
    PY="$REPO_DIR/.venv/bin/python3"
else
    PY="python3"
fi
exec "$PY" "$REPO_DIR/sitemap_parser.py" "$@"
