# H3 cells-to-polygon benchmarks

Compares the performance of H3's cells-to-polygon functions across different
versions of the library, using the Colorado state boundary as a test polygon
at resolutions 3-8.

## Checkpoints

Each checkpoint is a snapshot of the H3 library at a specific point in time,
paired with a benchmark that exercises the cells-to-polygon API available in
that version.

| Checkpoint | H3 version | Function benchmarked        |
|------------|------------|-----------------------------|
| `master`   | Latest     | `cellsToMultiPolygon` (new) |
| `v4.4.1`   | v4.4.1     | `cellsToLinkedMultiPolygon` |

## Project structure

```
checkpoints/
  master/
    h3/                      git submodule pinned to master
    benchmarkColorado.c      benchmark source
  v4.4.1/
    h3/                      git submodule pinned to v4.4.1 tag
    benchmarkColorado.c      benchmark source
bench.py                     runs binaries, parses output, reports results
justfile                     builds h3 + benchmarks, orchestrates runs
```

## Usage

```
git clone --recursive <this-repo>
just
```

This builds both H3 versions, compiles the benchmarks against `libh3.a`,
runs each benchmark binary 5 times, and reports the minimum time per
resolution across runs.

## How it works

1. **Build**: For each checkpoint, `just` builds `libh3.a` via cmake, then
   compiles `benchmarkColorado.c` against it with `cc -O3`. The H3 submodule
   source is never modified.

2. **Run**: `bench.py` executes each compiled benchmark binary multiple times
   (default 5). Each run internally iterates the function many times per
   resolution (10,000 at res 3, down to 5 at res 8) and reports the average.

3. **Report**: The minimum average across runs is taken for each resolution,
   filtering out system noise. Results are printed as a side-by-side table
   and written to `results/results.json`.

## Adding a new checkpoint

1. `mkdir checkpoints/<name>`
2. `git submodule add https://github.com/uber/h3.git checkpoints/<name>/h3`
3. `cd checkpoints/<name>/h3 && git checkout <tag-or-commit>`
4. Write `checkpoints/<name>/benchmarkColorado.c` using the API from that version
5. Run `just` -- the new checkpoint is discovered automatically
