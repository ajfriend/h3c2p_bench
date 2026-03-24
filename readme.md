# H3 cells-to-polygon benchmarks

Compares the performance of H3's cells-to-polygon functions across H3 library
versions, using the Colorado state boundary as a test polygon at resolutions
3–9.

## Checkpoints

| Checkpoint | H3 source                                                          | Function benchmarked                              |
|------------|--------------------------------------------------------------------|---------------------------------------------------|
| `v4.4.1`   | [uber/h3 v4.4.1](https://github.com/uber/h3/tree/v4.4.1)           | `cellsToLinkedMultiPolygon`                       |
| `v4.5a`    | [uber/h3 master](https://github.com/uber/h3)                       | `cellsToMultiPolygon`                             |
| `gosper`   | [ajfriend/h3 gosper branch](https://github.com/ajfriend/h3/pull/3) | `cellsToMultiPolygonGosper` (pre-compacted input) |
| `gosper+c` | [ajfriend/h3 gosper branch](https://github.com/ajfriend/h3/pull/3) | `compactCells` + `cellsToMultiPolygonGosper`      |

- **v4.4.1**: The old cells-to-polygon algorithm, before the rewrite.
- **v4.5a**: The rewritten algorithm (planned for v4.5), without the Gosper optimization.
- **gosper**: The Gosper-based algorithm operating on pre-compacted cells (compaction time not measured).
- **gosper+c**: Same, but includes `compactCells` in the timed section — a fairer end-to-end comparison starting from uncompacted input.

## Results

Times are the minimum across 5 runs. **vs** columns show speedup relative
to `v4.4.1` (ratio of `v4.4.1` time / checkpoint time). **cells** and
**compact** are the input sizes before and after `compactCells`.

Example timings from an M3 MacBook Air:

| resolution     |     cells | compact |  v4.4.1 |   v4.5a | gosper | gosper+c | v4.5a vs | gosper vs | gosper+c vs |
|----------------|----------:|--------:|--------:|--------:|-------:|---------:|---------:|----------:|------------:|
| colorado_res_3 |        20 |      14 |    27µs |    15µs |   14µs |     14µs |     1.8x |      1.9x |        1.9x |
| colorado_res_4 |       140 |      56 |   159µs |    55µs |   46µs |     47µs |     2.9x |      3.4x |        3.4x |
| colorado_res_5 |       974 |     170 |   1.2ms |   309µs |  163µs |    170µs |     3.8x |      7.3x |        7.0x |
| colorado_res_6 |     6,831 |     501 |   8.2ms |   2.0ms |  566µs |    620µs |     4.1x |     14.5x |       13.3x |
| colorado_res_7 |    47,823 |   1,419 |  55.1ms |  22.0ms |  2.0ms |    2.5ms |     2.5x |     27.2x |       22.2x |
| colorado_res_8 |   334,719 |   3,813 | 409.2ms | 270.5ms |  7.0ms |   10.1ms |     1.5x |     58.7x |       40.4x |
| colorado_res_9 | 2,343,047 |  10,169 |  14.05s |   2.00s | 35.0ms |   70.8ms |     7.0x |    401.4x |      198.3x |

## Usage

```
git clone --recursive https://github.com/ajfriend/h3c2p_bench.git
cd h3c2p_bench
just
```

Requires: cmake, a C compiler, [just](https://github.com/casey/just),
and [uv](https://github.com/astral-sh/uv).

See [architecture.md](architecture.md) for build details and how to add new
checkpoints.
