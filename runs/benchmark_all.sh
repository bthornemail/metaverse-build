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
