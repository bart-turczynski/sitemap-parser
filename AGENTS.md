# sitemap-parser

A Claude Code skill wrapping `ultimate-sitemap-parser` to extract a website's sitemap to CSV/TXT.

Python 3.10+, declared once as `requires-python` in `pyproject.toml` and parsed from there by
`install.sh`, which selects a qualifying interpreter from `PATH`. macOS `/usr/bin/python3` is 3.9
and does not qualify. `pyproject.toml` is metadata only: no build backend, and
dependencies stay in `requirements.txt`.

`install.sh` creates `.venv/` from the pinned `requirements.txt` and symlinks `skill/` — not the
repository root — into `~/.claude/skills/sitemap-parser`. Keep `skill/` to what Claude reads:
anything added to it is served as part of the skill. Invoke the CLI through `./skill/run.sh`, not
`python3 sitemap_parser.py` — it selects `.venv/bin/python3` when present and finds the CLI by
resolving its own location, so it works through the symlink too.

`sitemap_parser.py` prints exactly one line: the absolute path of the generated file. Anything
else on stdout breaks the response contract in `skill/SKILL.md`.

Installation is a symlink, so a change here reaches every installed copy at once. The flag
table in `README.md` and the flag mapping in `skill/SKILL.md` describe the same surface — change
both together.

For flags, output filenames and CSV columns, see README.md.
