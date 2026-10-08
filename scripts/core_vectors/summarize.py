#!/usr/bin/env python3
"""Summarizes results.jsonl from run.py.

    summarize.py <results.jsonl> [--markdown]

Checks are split by their flags: "consensus" when every flag is enforced by mainnet consensus
today, "policy" when at least one is a relay policy flag.
"""
import collections
import json
import sys

CONSENSUS_FLAGS = {"", "NONE", "P2SH", "DERSIG", "NULLDUMMY", "CHECKLOCKTIMEVERIFY",
                   "CHECKSEQUENCEVERIFY", "WITNESS", "TAPROOT"}


def flag_class(result):
    flags = result.get("flags", "").split(",")
    return "consensus" if all(f in CONSENSUS_FLAGS for f in flags) else "policy"


results = [json.loads(line) for line in open(sys.argv[1])]
markdown = "--markdown" in sys.argv

for cls in ("consensus", "policy"):
    subset = [r for r in results if flag_class(r) == cls]
    total = collections.Counter(r["kind"] for r in subset)
    print(f"{cls} flags: {len(subset)} checks, {total['ok']} agree with Bitcoin Core, "
          f"{total['soundness']} soundness failures, {total['completeness']} completeness failures")
print()

table = collections.defaultdict(collections.Counter)
for r in results:
    table[(r["source"], r["category"], flag_class(r))][r["kind"]] += 1
if markdown:
    print("| Source | Category | Flags | Checks | Agree | Soundness | Completeness |")
    print("| --- | --- | --- | ---: | ---: | ---: | ---: |")
for (source, category, cls), counts in sorted(table.items()):
    n = sum(counts.values())
    if markdown:
        print(f"| {source} | {category} | {cls} | {n} | {counts['ok']} | {counts['soundness']} | {counts['completeness']} |")
    else:
        print(f"{source:14} {category:38} {cls:9} {n:5} ok={counts['ok']:5} "
              f"sound={counts['soundness']:4} complete={counts['completeness']:4}")

print()
print("Soundness failures (Bitcoin Core rejects, engine accepts):")
for r in results:
    if r["kind"] == "soundness":
        print(f"  [{flag_class(r)}] {r['id']}: {r['description']}")

print()
print("Completeness failures by engine outcome:")
groups = collections.defaultdict(list)
for r in results:
    if r["kind"] == "completeness":
        groups[r["outcome"][:90]].append(r)
for outcome, rs in sorted(groups.items(), key=lambda kv: -len(kv[1])):
    cats = collections.Counter(f"{r['category']}/{flag_class(r)}" for r in rs)
    print(f"  {len(rs):4} {outcome}  [{', '.join(f'{c}:{n}' for c, n in cats.most_common(6))}]")
    for r in rs[:3]:
        print(f"         e.g. {r['id']}: {r['description'][:150]}")
