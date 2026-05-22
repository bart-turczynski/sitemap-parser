#!/usr/bin/env bash
# Resolve to the real directory even when invoked through a symlink.
SKILL_DIR="$(cd "$(dirname "$0")" && pwd -P)"
if [ -x "$SKILL_DIR/.venv/bin/python3" ]; then
    PY="$SKILL_DIR/.venv/bin/python3"
else
    PY="python3"
fi
exec "$PY" "$SKILL_DIR/sitemap_parser.py" "$@"
