#!/usr/bin/env python3
"""Deterministic wrapper around ultimate-sitemap-parser. Prints one line: the output path."""
import argparse
import csv
import logging
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from urllib.parse import urlparse

logging.disable(logging.CRITICAL)

from usp.tree import sitemap_tree_for_homepage

COLS = ["url", "last_modified", "priority", "change_frequency", "images", "alternates", "news_story"]


def slug(s: str) -> str:
    s = s.strip("/").replace("/", "-")
    s = re.sub(r"[^A-Za-z0-9-]+", "-", s)
    return s.strip("-") or "filter"


def domain_of(url: str) -> str:
    host = urlparse(url if "://" in url else f"https://{url}").netloc or url
    return host.removeprefix("www.")


def row_for(p) -> list:
    return [
        p.url,
        p.last_modified.isoformat() if p.last_modified else "",
        str(p.priority) if p.priority is not None else "",
        p.change_frequency.value if p.change_frequency else "",
        "|".join(str(i.loc) for i in (p.images or [])),
        "|".join(f"{lang}:{u}" for lang, u in (p.alternates or [])),
        "yes" if p.news_story else "",
    ]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("url")
    ap.add_argument("-i", "--include")
    ap.add_argument("-e", "--exclude")
    ap.add_argument("-r", "--recent", type=int)
    ap.add_argument("-o", "--output", default=".")
    ap.add_argument("-f", "--flat", action="store_true")
    ap.add_argument("-s", "--structure", action="store_true")
    args = ap.parse_args()

    out_dir = Path(args.output).expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    domain = domain_of(args.url)
    date_str = datetime.now().strftime("%Y-%m-%d")

    tree = sitemap_tree_for_homepage(args.url)

    if args.structure:
        rows = []

        def walk(node, depth=0):
            count = sum(1 for _ in node.all_pages()) if hasattr(node, "all_pages") else 0
            rows.append((depth, node.url, count))
            for sub in getattr(node, "sub_sitemaps", []):
                walk(sub, depth + 1)

        walk(tree)
        out = out_dir / f"{domain}_sitemap_structure_{date_str}.csv"
        with out.open("w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["depth", "sitemap_url", "page_count"])
            w.writerows(rows)
        print(out)
        return 0

    pages = tree.all_pages()
    if args.include:
        pages = (p for p in pages if args.include in p.url)
    if args.exclude:
        pages = (p for p in pages if args.exclude not in p.url)
    if args.recent is not None:
        cutoff = datetime.now(timezone.utc) - timedelta(days=args.recent)
        pages = (p for p in pages if p.last_modified and p.last_modified > cutoff)

    parts = [domain, "sitemap"]
    if args.include:
        parts.append(slug(args.include))
    if args.exclude:
        parts.append(f"not-{slug(args.exclude)}")
    if args.recent is not None:
        parts.append(f"recent{args.recent}d")
    parts.append(date_str)
    ext = "txt" if args.flat else "csv"
    out = out_dir / f"{'_'.join(parts)}.{ext}"

    if args.flat:
        with out.open("w", encoding="utf-8") as f:
            for p in pages:
                f.write(p.url + "\n")
    else:
        with out.open("w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(COLS)
            for p in pages:
                w.writerow(row_for(p))

    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
