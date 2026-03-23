default: run

# Build h3 library + benchmark binary for one checkpoint
[private]
compile checkpoint:
    #!/usr/bin/env bash
    set -euo pipefail
    h3=checkpoints/{{checkpoint}}/h3
    cmake -B $h3/build -S $h3 -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -1
    cmake --build $h3/build --target h3 -j 2>&1 | tail -3
    cc -O2 \
       -I $h3/build/src/h3lib/include \
       -I $h3/src/h3lib/include \
       -I $h3/src/apps/applib/include \
       checkpoints/{{checkpoint}}/benchmarkColorado.c \
       $h3/build/lib/libh3.a \
       -lm -o checkpoints/{{checkpoint}}/benchmarkColorado

# Build all checkpoints
build:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in checkpoints/*/; do
        name=$(basename "$dir")
        echo "=== Building $name ==="
        just compile "$name"
    done

# Build + run + report
run: build
    uv run bench.py

clean:
    rm -rf checkpoints/*/h3/build checkpoints/*/benchmarkColorado results
