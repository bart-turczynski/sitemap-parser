# sitemap-parser

A Claude Code skill that wraps [ultimate-sitemap-parser](https://pypi.org/project/ultimate-sitemap-parser/) so you can extract a website's sitemap to CSV/TXT from natural-language requests in Claude.

## What you can ask Claude

- "Extract example.com's sitemap"
- "Get all /blog/ URLs from example.com and save to ~/Downloads"
- "Show me example.com pages updated in the last 7 days"
- "Give me a flat URL list from example.com"
- "Show the sitemap structure of example.com"

Filters combine: include + exclude + recent-N-days, plus an optional output directory.

## Install (quick)

```bash
git clone https://github.com/bart-turczynski/sitemap-parser.git "$HOME/Projects/sitemap-parser"
"$HOME/Projects/sitemap-parser/install.sh"
```

`install.sh` creates a project-local Python venv, installs the parser library, symlinks the skill into `~/.claude/skills/`, and runs a probe against tidio.com to verify the install. After it finishes, restart Claude Code so it picks up the new skill.

## Install (manual)

If you prefer step-by-step. `$REPO_DIR` stands for wherever you put the repo on your machine.

1. **Clone the repo**:

   ```bash
   REPO_DIR="$HOME/Projects/sitemap-parser"
   git clone https://github.com/bart-turczynski/sitemap-parser.git "$REPO_DIR"
   ```

2. **Install the parser library** into a venv inside the repo:

   ```bash
   python3 -m venv "$REPO_DIR/.venv"
   "$REPO_DIR/.venv/bin/pip" install ultimate-sitemap-parser
   ```

3. **Symlink the skill** into Claude's user-level skills folder:

   ```bash
   ln -s "$REPO_DIR" "$HOME/.claude/skills/sitemap-parser"
   ```

4. **Verify** (optional):

   ```bash
   "$REPO_DIR/run.sh" https://tidio.com --output /tmp
   ```

   Should print a path like `/tmp/tidio.com_sitemap_2026-05-22.csv`.

## Direct CLI use (no Claude)

You can also call the script directly:

```bash
~/.claude/skills/sitemap-parser/run.sh <URL> [flags]
```

| Flag | Effect |
|---|---|
| `-i, --include <substr>` | URL must contain this substring |
| `-e, --exclude <substr>` | URL must NOT contain this substring |
| `-r, --recent <N>` | Only URLs modified in the last N days |
| `-f, --flat` | TXT output, one URL per line |
| `-s, --structure` | Dump sitemap tree shape (depth / sitemap URL / page count) |
| `-o, --output <dir>` | Output directory (default: cwd) |

Filters combine. `--structure` ignores the other filters.

## Output

| Operation | Filename |
|---|---|
| Full dump | `<domain>_sitemap_<YYYY-MM-DD>.csv` |
| Include filter | `<domain>_sitemap_<slug>_<YYYY-MM-DD>.csv` |
| Exclude filter | `<domain>_sitemap_not-<slug>_<YYYY-MM-DD>.csv` |
| Recent | `<domain>_sitemap_recent<N>d_<YYYY-MM-DD>.csv` |
| Flat list | same as above, `.txt` extension, one URL per line |
| Structure | `<domain>_sitemap_structure_<YYYY-MM-DD>.csv` (cols: depth, sitemap_url, page_count) |

CSV columns: `url, last_modified, priority, change_frequency, images, alternates, news_story`.

## How it works

- `SKILL.md` — the natural-language → flag mapping Claude reads.
- `sitemap_parser.py` — deterministic Python CLI. Prints exactly one line: the path to the generated file.
- `run.sh` — picks `.venv/bin/python3` if present, otherwise system `python3`.
- `install.sh` — sets up the venv and the symlink.

No LLM is involved at runtime — the skill is just a translation layer. The Python script does all the work.
