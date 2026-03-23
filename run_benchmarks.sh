#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
mkdir -p "$RESULTS_DIR"

NCPU="$(sysctl -n hw.logicalcpu)"

add_benchmark() {
    local h3_dir="$1"
    local name="$2"
    local src="$3"
    cp "$SCRIPT_DIR/$src" "$h3_dir/src/apps/benchmarks/$src"
    if ! grep -q "$name" "$h3_dir/CMakeLists.txt"; then
        sed -i '' "/add_h3_benchmark(benchmarkH3Api/a\\
    add_h3_benchmark($name src/apps/benchmarks/$src)
" "$h3_dir/CMakeLists.txt"
    fi
}

build_and_run() {
    local h3_dir="$1"
    local name="$2"
    local outfile="$3"
    cd "$h3_dir"
    cmake -B build -DBUILD_BENCHMARKS=ON -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -1
    cmake --build build --target "$name" -j "$NCPU" 2>&1 | tail -3
    echo "Running $name..."
    ./build/bin/"$name" | tee "$outfile"
    cd "$SCRIPT_DIR"
}

# --- Benchmark 1: latest master, cellsToMultiPolygon ---
H3_MASTER="$SCRIPT_DIR/h3-master"
echo "============================================"
echo "Benchmark: cellsToMultiPolygon @ master ($(cd "$H3_MASTER" && git rev-parse --short HEAD))"
echo "============================================"
add_benchmark "$H3_MASTER" benchmarkColoradoDirect benchmarkColoradoDirect.c
build_and_run "$H3_MASTER" benchmarkColoradoDirect "$RESULTS_DIR/master_direct.txt"

# --- Benchmark 2: v4.4.1, cellsToLinkedMultiPolygon ---
H3_RELEASE="$SCRIPT_DIR/h3-release"
echo ""
echo "============================================"
echo "Benchmark: cellsToLinkedMultiPolygon @ v4.4.1 ($(cd "$H3_RELEASE" && git rev-parse --short HEAD))"
echo "============================================"
add_benchmark "$H3_RELEASE" benchmarkColoradoLinked benchmarkColoradoLinked.c
build_and_run "$H3_RELEASE" benchmarkColoradoLinked "$RESULTS_DIR/v4.4.1_linked.txt"

# --- Summary ---
echo ""
echo "============================================"
echo "Results saved to $RESULTS_DIR/"
echo "============================================"
echo ""
echo "--- master (cellsToMultiPolygon) ---"
cat "$RESULTS_DIR/master_direct.txt"
echo ""
echo "--- v4.4.1 (cellsToLinkedMultiPolygon) ---"
cat "$RESULTS_DIR/v4.4.1_linked.txt"
