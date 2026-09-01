# sitemap-parser

A Claude Code skill wrapping `ultimate-sitemap-parser` to extract a website's sitemap to CSV/TXT.

`install.sh` creates `.venv/` from the pinned `requirements.txt` and symlinks the repo into
`~/.claude/skills/sitemap-parser`. Invoke the CLI through `./run.sh`, not
`python3 sitemap_parser.py` — `run.sh` selects `.venv/bin/python3` when present.

`sitemap_parser.py` prints exactly one line: the absolute path of the generated file. Anything
else on stdout breaks the response contract in `SKILL.md`.

Installation is a symlink, so a change here reaches every installed copy at once. The flag
table in `README.md` and the flag mapping in `SKILL.md` describe the same surface — change
both together.

For flags, output filenames and CSV columns, see README.md.
