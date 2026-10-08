#!/usr/bin/env python3
"""Runs the cases produced by vectors.py through the harness and compares with Bitcoin Core.

    run.py <cases.jsonl> <results.jsonl> [--jobs N] [--batch N] [--filter TEXT]

Run it from scripts/core_vectors/harness after `scarb build`. Cases run in batches through the
`run_cases` executable; a batch that panics is rerun one case at a time through `run_case`, so a
panic is attributed to the case that caused it.

Each result is classified against Bitcoin Core's expectation:
- "ok": same verdict as Bitcoin Core;
- "soundness": Bitcoin Core rejects the input and the engine accepts it;
- "completeness": Bitcoin Core accepts the input and the engine rejects it or panics.
A panic on an input Bitcoin Core rejects counts as "ok": no proof could be produced from it.
"""
import argparse
import concurrent.futures
import json
import os
import re
import subprocess
import tempfile
import time

VALID = "VALID"


def felt_to_text(value):
    raw = value.to_bytes((value.bit_length() + 7) // 8, "big")
    try:
        text = raw.decode("ascii")
        if text.isprintable():
            return text
    except UnicodeDecodeError:
        pass
    return hex(value)


def execute(executable, felts, timeout):
    """Runs one execution and returns (ok, outputs or error text)."""
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
        json.dump([hex(x) for x in felts], f)
        path = f.name
    try:
        run = subprocess.run(
            ["scarb", "--offline", "execute", "--no-build", "--executable-name", executable,
             "--arguments-file", path, "--print-program-output", "--output", "none"],
            capture_output=True, text=True, timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return False, "TIMEOUT"
    finally:
        os.unlink(path)
    text = run.stdout + run.stderr
    if run.returncode != 0:
        match = re.search(r"Panicked with (.*)", text)
        return False, ("PANIC: " + match.group(1).strip()) if match else "FAILED: " + text.strip()[-300:]
    lines = text.split("Program output:", 1)[1].split("\n") if "Program output:" in text else []
    outputs = []
    for line in lines[1:]:
        line = line.strip()
        if not line or not re.fullmatch(r"-?\d+", line):
            break
        outputs.append(int(line))
    return True, outputs


def classify(case, outcome):
    accepted = outcome == VALID
    if accepted == case["expect_valid"]:
        return "ok"
    if accepted:
        return "soundness"
    if outcome.startswith("PANIC") and not case["expect_valid"]:
        return "ok"
    return "completeness"


def run_batch(batch, timeout):
    felts = [len(batch)] + [int(x, 16) for case in batch for x in case["args"]]
    started = time.time()
    ok, outputs = execute("run_cases", felts, timeout * len(batch))
    results = []
    if ok and len(outputs) == len(batch) + 1 and outputs[0] == len(batch):
        for case, value in zip(batch, outputs[1:]):
            results.append((case, felt_to_text(value)))
    else:
        for case in batch:
            ok, outputs = execute("run_case", [int(x, 16) for x in case["args"]], timeout)
            if ok and len(outputs) == 1:
                results.append((case, felt_to_text(outputs[0])))
            elif ok:
                results.append((case, f"BAD OUTPUT {outputs}"))
            else:
                results.append((case, outputs))
    elapsed = time.time() - started
    return [
        {"id": c["id"], "source": c["source"], "category": c["category"],
         "flags": c.get("flags", ""), "expect_valid": c["expect_valid"], "outcome": o,
         "kind": classify(c, o), "description": c["description"],
         "batch_seconds": round(elapsed, 1)}
        for c, o in results
    ]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("cases")
    parser.add_argument("results")
    parser.add_argument("--jobs", type=int, default=12)
    parser.add_argument("--batch", type=int, default=20)
    parser.add_argument("--timeout", type=int, default=600, help="seconds per case")
    parser.add_argument("--filter", default="")
    parser.add_argument("--exclude", action="append", default=[],
                        help="skip cases whose description contains this text (repeatable)")
    args = parser.parse_args()

    cases = [json.loads(line) for line in open(args.cases)]
    cases = [c for c in cases if args.filter in c["id"] or args.filter in c["description"]]
    cases = [c for c in cases if not any(x in c["description"] for x in args.exclude)]
    batches = [cases[i:i + args.batch] for i in range(0, len(cases), args.batch)]
    print(f"{len(cases)} cases in {len(batches)} batches, {args.jobs} jobs", flush=True)

    done = 0
    counts = {"ok": 0, "soundness": 0, "completeness": 0}
    started = time.time()
    with open(args.results, "w") as out, concurrent.futures.ThreadPoolExecutor(args.jobs) as pool:
        futures = [pool.submit(run_batch, b, args.timeout) for b in batches]
        for future in concurrent.futures.as_completed(futures):
            results = future.result()
            for r in results:
                out.write(json.dumps(r) + "\n")
                counts[r["kind"]] += 1
            out.flush()
            done += len(results)
            print(f"{done}/{len(cases)} {counts} {time.time() - started:.0f}s", flush=True)


if __name__ == "__main__":
    main()
