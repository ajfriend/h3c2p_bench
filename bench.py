"""Benchmark runner and reporter for H3 checkpoint comparison."""
# /// script
# dependencies = ["tabulate"]
# ///

import json
import re
import subprocess
import sys
from pathlib import Path

from tabulate import tabulate

RUNS = 5

ROOT = Path(__file__).resolve().parent
CHECKPOINTS_DIR = ROOT / "checkpoints"
RESULTS_DIR = ROOT / "results"

LINE_RE = re.compile(
    r"--\s+(?P<label>colorado_res_\d+):\s+"
    r"(?P<time>[\d.]+)\s+microseconds per iteration"
)


def discover_checkpoints():
    found = [
        d for d in sorted(CHECKPOINTS_DIR.iterdir())
        if d.is_dir() and (d / "h3").is_dir() and (d / "benchmarkColorado.c").is_file()
    ]
    if not found:
        sys.exit("No checkpoints found in checkpoints/")
    return found


def git_short_rev(checkpoint):
    r = subprocess.run(
        ["git", "rev-parse", "--short", "HEAD"],
        cwd=checkpoint / "h3", capture_output=True, text=True,
    )
    return r.stdout.strip() or "unknown"


def parse_output(text):
    return {
        m.group("label"): float(m.group("time"))
        for line in text.splitlines()
        if (m := LINE_RE.search(line))
    }


def run_benchmark(checkpoint):
    name = checkpoint.name
    binary = checkpoint / "benchmarkColorado"
    if not binary.exists():
        sys.exit(f"Binary not found: {binary}  (run 'just build' first)")

    raw_dir = RESULTS_DIR / "raw" / name
    raw_dir.mkdir(parents=True, exist_ok=True)

    all_results = []
    for i in range(1, RUNS + 1):
        print(f"  [{name}] run {i}/{RUNS}")
        r = subprocess.run([str(binary)], capture_output=True, text=True, check=True)
        (raw_dir / f"run_{i}.txt").write_text(r.stdout)
        all_results.append(parse_output(r.stdout))

    labels = list(all_results[0].keys())
    return {label: min(r[label] for r in all_results) for label in labels}


# --- Run benchmarks ---

checkpoints = discover_checkpoints()
all_data = {}

for cp in checkpoints:
    rev = git_short_rev(cp)
    print(f"\n=== {cp.name} (h3 @ {rev}) -- {RUNS} runs ===")
    all_data[cp.name] = run_benchmark(cp)

# --- Report ---

labels = list(next(iter(all_data.values())).keys())
table = [
    [label] + [f"{all_data[cp][label]:,.2f}" for cp in all_data]
    for label in labels
]
headers = ["resolution"] + list(all_data.keys())

print(f"\nResults ({RUNS} runs, minimum per resolution, µs)\n")
print(tabulate(table, headers=headers, colalign=("left", *("right",) * len(all_data))))

RESULTS_DIR.mkdir(parents=True, exist_ok=True)
(RESULTS_DIR / "results.json").write_text(
    json.dumps({"runs": RUNS, "checkpoints": all_data}, indent=2) + "\n"
)
