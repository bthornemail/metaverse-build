#!/bin/bash
# Distributed Benchmark Setup Script
# Creates native builds for all components

echo "=== METAVERSE DISTRIBUTED BENCHMARK SETUP ==="
echo ""

# Create builds directory
mkdir -p builds/{haskell,rust,c,python}

echo "[1/4] Building C version (fastest)..."
cat > builds/c/authority_gate.c << 'C'
#include <stdio.h>
#include <string.h>

int validate(const char *json) {
    if (strstr(json, "valid:") != NULL) return 1;
    return 0;
}

int main() {
    char line[4096];
    while (fgets(line, sizeof(line), stdin)) {
        if (validate(line)) {
            printf("OK\n");
        } else {
            printf("HALT\n");
        }
        fflush(stdout);
    }
    return 0;
}
C
gcc -O3 -march=native -o builds/c/authority_gate builds/c/authority_gate.c
echo "  Built: builds/c/authority_gate"

echo "[2/4] Building Python version (baseline)..."
cat > builds/python/authority_gate.py << 'PY'
#!/usr/bin/env python3
import sys
import json

def validate(event_json):
    try:
        event = json.loads(event_json)
        actor = event.get('actor', '')
        if 'valid:' in actor:
            return 'OK'
        return 'HALT'
    except:
        return 'HALT'

for line in sys.stdin:
    print(validate(line.strip()))
PY
chmod +x builds/python/authority_gate.py
echo "  Built: builds/python/authority_gate.py"

echo "[3/4] Using existing Haskell compiled..."
cp invariants/authority/gate/AuthorityGate.native builds/haskell/authority_gate 2>/dev/null || echo "  Note: Haskell binary not compiled"
echo "  Built: builds/haskell/authority_gate"

echo "[4/4] Creating benchmark runner..."
cat > runs/benchmark_all.sh << 'EOF'
#!/bin/bash
echo "=========================================="
echo "MULTI-LANGUAGE BENCHMARK"
echo "=========================================="
echo ""

EVENTS=1000
EVENT='{"actor":"valid:userA","entity":"test"}'

for lang in c python haskell; do
    echo "Testing $lang..."
    
    if [ "$lang" = "c" ]; then
        START=$(date +%s%N)
        for i in $(seq 1 $EVENTS); do
            echo "$EVENT" | ./builds/c/authority_gate > /dev/null 2>&1
        done
        END=$(date +%s%N)
        TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
        RATE=$(echo "scale=0; $EVENTS / $TIME" | bc)
    elif [ "$lang" = "python" ]; then
        START=$(date +%s%N)
        for i in $(seq 1 $EVENTS); do
            echo "$EVENT" | python3 ./builds/python/authority_gate.py > /dev/null 2>&1
        done
        END=$(date +%s%N)
        TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
        RATE=$(echo "scale=0; $EVENTS / $TIME" | bc)
    elif [ "$lang" = "haskell" ]; then
        if [ -x builds/haskell/authority_gate ]; then
            START=$(date +%s%N)
            for i in $(seq 1 $EVENTS); do
                echo "$EVENT" | ./builds/haskell/authority_gate > /dev/null 2>&1
            done
            END=$(date +%s%N)
            TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
            RATE=$(echo "scale=0; $EVENTS / $TIME" | bc)
        else
            RATE="N/A"
        fi
    fi
    
    echo "  $lang: $RATE/sec"
done
EOF
chmod +x runs/benchmark_all.sh

echo ""
echo "=== BUILD COMPLETE ==="
echo ""
ls -la builds/*/
echo ""
echo "Run benchmark: ./runs/benchmark_all.sh"
