#!/bin/bash
echo "=== ULTIMATE C NATIVE BENCHMARK ==="
echo ""

# Build ultimate C version
cat > /tmp/ultimate_gate.c << 'C'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int validate(const char *json) {
    return strstr(json, "valid:") != NULL;
}

int main() {
    char line[4096];
    int count = 0;
    
    while (fgets(line, sizeof(line), stdin)) {
        if (validate(line)) {
            count++;
        }
    }
    
    printf("Processed %d events\n", count);
    return 0;
}
C

echo "[1] Building ultimate C native..."
gcc -O3 -march=native -o /tmp/ultimate_gate /tmp/ultimate_gate.c

echo "[2] Testing different approaches..."
EVENT='{"actor":"valid:userA","entity":"test"}'

echo -n "Subprocess spawn: "
time (for i in $(seq 1 100); do echo "$EVENT" | /tmp/ultimate_gate > /dev/null 2>&1; done)

echo -n "In-process (100 events): "
START=$(date +%s%N)
for i in $(seq 1 100); do
    echo "$EVENT"
done | /tmp/ultimate_gate > /dev/null
END=$(date +%s%N)
TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
RATE=$(echo "scale=0; 100 / $TIME" | bc)
echo "${RATE}/sec"

echo -n "In-process (1000 events): "
START=$(date +%s%N)
for i in $(seq 1 1000); do
    echo "$EVENT"
done | /tmp/ultimate_gate > /dev/null
END=$(date +%s%N)
TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
RATE=$(echo "scale=0; 1000 / $TIME" | bc)
echo "${RATE}/sec"

echo -n "In-process (10000 events): "
START=$(date +%s%N)
for i in $(seq 1 10000); do
    echo "$EVENT"
done | /tmp/ultimate_gate > /dev/null
END=$(date +%s%N)
TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
RATE=$(echo "scale=0; 10000 / $TIME" | bc)
echo "${RATE}/sec"

echo ""
echo "=== OPTIMIZATION COMPLETE ==="
