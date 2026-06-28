#!/usr/bin/env python3
"""Maintain the "## スタック（PR シリーズ）" section across a stacked PR chain.

Auto-discovers the open PR chain that contains ``--pr``, carries the previously
rendered stack list (including merged ancestors and their descriptions) forward
from the existing section, refreshes merged/open status, appends any new open
PR, and patches every open PR's body — replacing ONLY the stack section so the
rest of each body (including images the author pasted) is preserved.

Usage:
    apply_stack.py --pr 2085 [--repo owner/name] \
        [--desc "2085=機能の概要 (TICKET-123)"] [--dry-run]

``--desc`` may be repeated; it sets the bullet description for a PR that is not
yet in the remembered list (a newly added PR). Descriptions of PRs already in
the section are carried forward verbatim, so re-running is idempotent.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

HEADER = "## スタック（PR シリーズ）"
INTRO = "`(this)` が本 PR。左がベース（先にマージ）。"
BULLET = re.compile(r"^- (~~)?#(\d+)~?~? (.+?)\s*$")


def gh(args):
    result = subprocess.run(
        ["gh"] + args, text=True, capture_output=True
    )
    if result.returncode != 0:
        sys.exit(f"gh {' '.join(args)} failed:\n{result.stderr}")
    return result.stdout


def repo_flag(repo):
    return ["--repo", repo] if repo else []


def open_prs(repo):
    raw = gh(
        ["pr", "list", "--state", "open", "--limit", "200", "--json",
         "number,baseRefName,headRefName,title"] + repo_flag(repo)
    )
    return json.loads(raw)


def discover_chain(start, prs):
    by_head = {p["headRefName"]: p for p in prs}
    chain = [start]
    cur = start
    while cur["baseRefName"] in by_head:
        cur = by_head[cur["baseRefName"]]
        chain.insert(0, cur)
    cur = start
    while True:
        ups = [p for p in prs if p["baseRefName"] == cur["headRefName"]]
        if not ups:
            break
        cur = ups[0]
        chain.append(cur)
    return chain  # base -> tip


def body_of(number, repo):
    return gh(
        ["pr", "view", str(number), "--json", "body", "-q", ".body"]
        + repo_flag(repo)
    ).replace("\r\n", "\n")


def parse_remembered(body):
    """Ordered [(number, desc)] from the existing stack section, if any."""
    if HEADER not in body:
        return []
    out = []
    for line in body.split("\n"):
        m = BULLET.match(line)
        if m:
            out.append((int(m.group(2)), m.group(3)))
    return out


def build_stack(chain, remembered, desc_overrides):
    chain_nums = [p["number"] for p in chain]
    open_set = set(chain_nums)
    title_by_num = {p["number"]: p["title"] for p in chain}
    desc_by_num = dict(remembered)
    desc_by_num.update(desc_overrides)

    order = [n for n, _ in remembered]
    for n in chain_nums:
        if n not in order:
            order.append(n)

    stack = []
    for n in order:
        desc = desc_by_num.get(n) or title_by_num.get(n) or ""
        stack.append({"number": n, "desc": desc, "merged": n not in open_set})
    return stack


def token(entry, this):
    n = entry["number"]
    base = f"~~#{n}~~" if entry["merged"] else f"#{n}"
    return base + (" (this)" if this else "")


def render(stack, this_number):
    chain = " → ".join(token(e, e["number"] == this_number) for e in stack)
    bullets = "\n".join(
        f"- {('~~#%d~~' % e['number']) if e['merged'] else '#%d' % e['number']}"
        f" {e['desc']}"
        for e in stack
    )
    return f"{HEADER}\n\n{INTRO}\n\n{chain}\n\n{bullets}"


def replace_section(body, section):
    lines = body.split("\n")
    try:
        start = next(i for i, l in enumerate(lines) if l.strip() == HEADER)
    except StopIteration:
        foot = next((i for i, l in enumerate(lines) if l.strip() == "---"), None)
        if foot is not None:
            return "\n".join(lines[:foot] + [section, ""] + lines[foot:])
        return body.rstrip("\n") + "\n\n" + section + "\n"
    end = len(lines)
    for i in range(start + 1, len(lines)):
        if lines[i].startswith("## ") or lines[i].strip() == "---":
            end = i
            break
    tail = lines[end:]
    middle = section.split("\n") + ([""] if tail else [])
    return "\n".join(lines[:start] + middle + tail)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--pr", type=int, required=True,
                    help="any open PR in the stack (usually the newly added one)")
    ap.add_argument("--repo", help="owner/name; defaults to the current repo")
    ap.add_argument("--desc", action="append", default=[],
                    metavar="NUMBER=説明",
                    help="bullet description for a PR not yet in the section")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    overrides = {}
    for d in a.desc:
        num, _, text = d.partition("=")
        overrides[int(num)] = text.strip()

    prs = open_prs(a.repo)
    start = next((p for p in prs if p["number"] == a.pr), None)
    if start is None:
        sys.exit(f"#{a.pr} is not an open PR in this repo")

    chain = discover_chain(start, prs)
    remembered = parse_remembered(body_of(chain[0]["number"], a.repo))
    stack = build_stack(chain, remembered, overrides)

    open_nums = [p["number"] for p in chain]
    merged_nums = [e["number"] for e in stack if e["merged"]]
    print("open chain (base→tip, auto-discovered):",
          " → ".join("#%d" % n for n in open_nums))
    if merged_nums:
        print("merged ancestors (carried forward from section):",
              ", ".join("#%d" % n for n in merged_nums))
    print("full stack:", " → ".join(token(e, False) for e in stack))
    for entry in stack:
        if entry["merged"]:
            continue
        n = entry["number"]
        body = body_of(n, a.repo)
        new_body = replace_section(body, render(stack, n))
        if a.dry_run:
            print(f"\n----- #{n} (dry-run) -----\n{new_body}")
            continue
        with tempfile.NamedTemporaryFile(
            "w", suffix=".md", delete=False, encoding="utf-8"
        ) as f:
            f.write(new_body)
            path = f.name
        try:
            gh(["pr", "edit", str(n), "--body-file", path] + repo_flag(a.repo))
            print(f"updated #{n}")
        finally:
            os.unlink(path)


if __name__ == "__main__":
    main()
