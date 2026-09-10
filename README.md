# sitemap-parser

A Claude Code skill that wraps [ultimate-sitemap-parser](https://pypi.org/project/ultimate-sitemap-parser/) so you can extract a website's sitemap to CSV/TXT from natural-language requests in Claude.

## What you can ask Claude

- "Extract example.com's sitemap"
- "Get all /blog/ URLs from example.com and save to ~/Downloads"
- "Show me example.com pages updated in the last 7 days"
- "Give me a flat URL list from example.com"
- "Show the sitemap structure of example.com"

Filters combine: include + exclude + recent-N-days, plus an optional output directory.

## Requirements

**Python 3.10 or newer**, because `ultimate-sitemap-parser` declares `Requires-Python >=3.10`. This repo declares the same floor as `requires-python` in `pyproject.toml`, and `install.sh` reads it from there — raising the floor is a one-line edit in one file. That `pyproject.toml` carries no build backend and is not installable; it exists so the version is declared where tooling looks for it, and the runtime dependency stays in `requirements.txt`.

This matters on macOS: `/usr/bin/python3` is Apple's 3.9, which is below the floor. `install.sh` searches `PATH` for a qualifying interpreter — plain `python3` first, then the highest `python3.x` it can find — and stops with the reason if there is none. Nothing is version-pinned beyond that floor, so a newer Python needs no change here.

Installing into a system or Homebrew Python instead of the venv does not work either: those interpreters are marked `EXTERNALLY-MANAGED` (PEP 668) and `pip` refuses to write to them. The venv is what makes the install possible, not ceremony.

## Install (quick)

```bash
git clone https://gitlab.com/bart-turczynski/sitemap-parser.git "$HOME/Projects/sitemap-parser"
"$HOME/Projects/sitemap-parser/install.sh"
```

`install.sh` creates a project-local Python venv, installs the pinned dependencies from `requirements.txt`, symlinks `skill/` into `~/.claude/skills/`, and probes a live site to verify the install. After it finishes, restart Claude Code so it picks up the new skill.

Re-running it is safe. An existing `.venv/` is reused when its interpreter meets the floor, and rebuilt from scratch when it does not — so a venv created before this check can be repaired by running the installer again.

The probe defaults to tidio.com. Set `PROBE_URL` to use a different site. If the probe host is unreachable the installer warns and still succeeds — only a reachable host that returns no URLs is treated as a failure.

## Install (manual)

If you prefer step-by-step. `$REPO_DIR` stands for wherever you put the repo on your machine.

1. **Clone the repo**:

   ```bash
   REPO_DIR="$HOME/Projects/sitemap-parser"
   git clone https://gitlab.com/bart-turczynski/sitemap-parser.git "$REPO_DIR"
   ```

2. **Install the dependencies** into a venv inside the repo. Substitute a specific
   interpreter for `python3` if yours is older than 3.10 (`python3.13 -m venv ...`):

   ```bash
   python3 -m venv "$REPO_DIR/.venv"
   "$REPO_DIR/.venv/bin/pip" install -r "$REPO_DIR/requirements.txt"
   ```

3. **Symlink the skill directory** — `skill/`, not the repository root — into
   Claude's user-level skills folder:

   ```bash
   ln -s "$REPO_DIR/skill" "$HOME/.claude/skills/sitemap-parser"
   ```

4. **Verify** (optional):

   ```bash
   "$REPO_DIR/skill/run.sh" https://tidio.com --output /tmp
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

- `skill/` — the whole of what Claude sees. `~/.claude/skills/sitemap-parser` links this directory, never the repository root: the runtime treats whatever it links as the skill package, and the root carries `.git`, `.venv`, this README and the installer, none of which belong in one.
- `skill/SKILL.md` — the natural-language → flag mapping Claude reads.
- `skill/run.sh` — resolves the repository from its own location, then picks `.venv/bin/python3` if present, otherwise system `python3`.
- `sitemap_parser.py` — deterministic Python CLI. Prints exactly one line: the path to the generated file.
- `install.sh` — picks a Python 3.10+ interpreter, sets up the venv and the symlink.
- `requirements.txt` — the pinned runtime dependency.
- `pyproject.toml` — declares the Python floor; metadata only, not installable.

No LLM is involved at runtime — the skill is just a translation layer. The Python script does all the work.
