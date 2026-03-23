# Architecture

## Project structure

```
checkpoints/
  <name>/
    h3/                      git submodule pinned to a version/branch
    benchmarkColorado.c      benchmark source
bench.py                     runs binaries, parses output, reports results
justfile                     builds h3 + benchmarks, orchestrates runs
```

## Build system

For each checkpoint, `just` builds `libh3.a` via cmake, then compiles
`benchmarkColorado.c` against it with `cc -O3`. The H3 submodule source
trees are never modified.

## Benchmarking approach

1. **C layer**: Each benchmark uses H3's `BENCHMARK` macro from `benchmark.h`,
   which times only the body (not setup). Iteration counts decrease with
   resolution (10,000 at res 3, down to 1 at res 9).

2. **Python layer**: `bench.py` executes each compiled binary multiple times
   (default 5, controlled by `RUNS`). The minimum average across runs is taken
   per resolution, filtering system noise.

3. **Output**: Results are printed as a table and written to
   `results/results.json`. Raw output from each run is saved to
   `results/raw/<checkpoint>/run_N.txt`.

## Adding a new checkpoint

1. `mkdir checkpoints/<name>`
2. `git submodule add <h3-repo-url> checkpoints/<name>/h3`
3. `cd checkpoints/<name>/h3 && git checkout <tag-or-commit>`
4. Write `checkpoints/<name>/benchmarkColorado.c` using the API from that version
5. Run `just` -- the new checkpoint is discovered automatically
