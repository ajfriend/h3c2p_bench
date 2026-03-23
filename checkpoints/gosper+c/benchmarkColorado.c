/*
 * Benchmark compactCells + cellsToMultiPolygonGosper on uncompacted Colorado
 * cells at resolutions 3-9.  Compaction time is included in the measurement.
 */

#include <stdlib.h>
#include <string.h>

#include "benchmark.h"
#include "cellsToMultiPoly.h"
#include "h3api.h"

static void getColoradoCells(int res, H3Index **outCells,
                             int64_t *outNumCells) {
    LatLng verts[] = {
        {H3_EXPORT(degsToRads)(37.0), H3_EXPORT(degsToRads)(-109.0)},
        {H3_EXPORT(degsToRads)(37.0), H3_EXPORT(degsToRads)(-102.0)},
        {H3_EXPORT(degsToRads)(41.0), H3_EXPORT(degsToRads)(-102.0)},
        {H3_EXPORT(degsToRads)(41.0), H3_EXPORT(degsToRads)(-109.0)},
    };
    GeoPolygon polygon = {
        .geoloop = {.numVerts = 4, .verts = verts},
        .numHoles = 0,
        .holes = NULL,
    };

    int64_t maxCells;
    H3_EXPORT(maxPolygonToCellsSize)(&polygon, res, 0, &maxCells);

    H3Index *cells = calloc(maxCells, sizeof(H3Index));
    H3_EXPORT(polygonToCells)(&polygon, res, 0, cells);

    int64_t numCells = 0;
    for (int64_t i = 0; i < maxCells; i++) {
        if (cells[i] != H3_NULL) {
            cells[numCells++] = cells[i];
        }
    }
    cells = realloc(cells, numCells * sizeof(H3Index));

    *outCells = cells;
    *outNumCells = numCells;
}

#define BENCH_COLORADO(RES, ITERS)                                           \
    {                                                                        \
        H3Index *cells;                                                      \
        int64_t numCells;                                                    \
        getColoradoCells(RES, &cells, &numCells);                            \
        H3Index *compact = malloc(numCells * sizeof(H3Index));               \
        BENCHMARK(colorado_res_##RES, ITERS, {                               \
            memset(compact, 0, numCells * sizeof(H3Index));                  \
            H3_EXPORT(compactCells)(cells, compact, numCells);               \
            int64_t numCompact = 0;                                          \
            for (int64_t i = 0; i < numCells; i++) {                         \
                if (compact[i] != H3_NULL)                                   \
                    compact[numCompact++] = compact[i];                      \
            }                                                                \
            GeoMultiPolygon mpoly;                                           \
            cellsToMultiPolygonGosper(compact, numCompact, RES, &mpoly);     \
            H3_EXPORT(destroyGeoMultiPolygon)(&mpoly);                       \
        });                                                                  \
        free(compact);                                                       \
        free(cells);                                                         \
    }

BEGIN_BENCHMARKS();

BENCH_COLORADO(3, 10000);
BENCH_COLORADO(4, 1000);
BENCH_COLORADO(5, 500);
BENCH_COLORADO(6, 100);
BENCH_COLORADO(7, 10);
BENCH_COLORADO(8, 5);
BENCH_COLORADO(9, 1);

END_BENCHMARKS();
