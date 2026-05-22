---
name: sitemap-parser
description: Extract URLs from a website's sitemap to CSV/TXT. Triggers - "extract sitemap", "get sitemap", "get all URLs from <site>", "save sitemap to CSV", "show sitemap structure". Wraps ultimate-sitemap-parser with include/exclude substring filters, recent-N-days, flat URL list, and sitemap-structure dump.
allowed-tools: Bash
---

# sitemap-parser

Deterministic wrapper. Translate the user's request to a single shell command, run it, output **only** the path it prints.

## Command

```
~/.claude/skills/sitemap-parser/run.sh <URL> [flags]
```

`<URL>` is required and positional. All flags are optional and combinable.

## Flag mapping

| User intent | Flag |
|---|---|
| URLs containing X (path, substring, "in /X/") | `--include X` |
| Exclude X (no /X/, without X) | `--exclude X` |
| Recently modified (N days, "recent", "updated lately") | `--recent N` (use 30 if no number given) |
| Flat URL list / TXT / one per line / for Screaming Frog | `--flat` |
| Sitemap structure / index / which sub-sitemaps exist | `--structure` |
| Save into directory Y | `--output Y` |

If no output directory is specified, omit `--output` (script defaults to cwd).

`--structure` ignores `--include`, `--exclude`, `--recent`, `--flat`.

## Response

The script prints exactly one line: the absolute path of the generated file. Your entire response to the user is that path, verbatim. No prose, no commentary, no formatting.
