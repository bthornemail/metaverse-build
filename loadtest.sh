#!/bin/bash
echo "======================================"
echo "METAVERSE BUILD RUNTIME - LOAD TEST"
echo "======================================"
echo "Date: $(date)"

RESULTS="reports/loadtest_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p reports

echo "METAVERSE LOAD TEST RESULTS" > "$RESULTS"
echo "Date: $(date)" >> "$RESULTS"
echo "--------------------------------------" >> "$RESULTS"

echo "Loading world..."
bash runtime/world/load-ir.sh world-ir/build/room.ir.json > /dev/null 2>&1

echo ""
echo "1. EVENT PROCESSING (100, 1K)"
echo "------------------------------"
echo "1. EVENT PROCESSING" >> "$RESULTS"

for level in 100 1000; do
    echo -n "   $level events: "
    event_file="/tmp/lt_e_$$.jsonl"
    
    python3 -c "
import json, sys
for i in range($level):
    sys.stdout.write(json.dumps({'type':'COMPONENT_UPDATE','entity':f'cube-{i%10}','component':'transform','patch':{'position':[i,i,i]},'actor':'valid:userA'}) + '\n')
" > "$event_file"
    
    START=$(date +%s%N)
    while IFS= read -r event; do
        python3 runtime/world/apply-event.py runtime/world/snapshots/room.snapshot.json > /dev/null 2>&1 || true
    done < "$event_file"
    END=$(date +%s%N)
    
    t=$(echo "scale=2; ($END - $START) / 1000000000" | bc)
    tp=$(echo "scale=1; $level / $t" | bc)
    echo "${tp}/sec"
    echo "$level: ${tp}/sec" >> "$RESULTS"
    rm -f "$event_file"
done

echo ""
echo "2. TRACE APPEND (1K, 10K)"
echo "--------------------------"
echo "2. TRACE APPEND" >> "$RESULTS"

for level in 1000 10000; do
    echo -n "   $level trace: "
    trace_file="/tmp/lt_t_$$.jsonl"
    
    python3 -c "
import json, sys
for i in range($level):
    sys.stdout.write(json.dumps({'type':'ENTITY_CREATE','id':f'test-{i}','owner':'valid:userA','actor':'valid:userA'}) + '\n')
" > "$trace_file"
    
    START=$(date +%s%N)
    cat "$trace_file" >> /tmp/lt_a_$$.jsonl
    END=$(date +%s%N)
    
    t=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
    tp=$(echo "scale=0; $level / $t" | bc)
    echo "${tp}/sec"
    echo "$level: ${tp}/sec" >> "$RESULTS"
    rm -f "$trace_file" /tmp/lt_a_$$.jsonl
done

echo ""
echo "3. BRANCHES (10, 100, 1K)"
echo "--------------------------"
echo "3. BRANCHES" >> "$RESULTS"

for level in 10 100 1000; do
    echo -n "   $level branches: "
    START=$(date +%s%N)
    for i in $(seq 1 $level); do
        python3 runtime/time/branch.py runtime/time/state/timeline.json ck-1 /tmp/b_$i.json > /dev/null 2>&1 || true
    done
    END=$(date +%s%N)
    
    t=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
    avg=$(echo "scale=4; $t / $level" | bc)
    echo "${avg}s avg"
    echo "$level: ${avg}s avg" >> "$RESULTS"
done

echo ""
echo "4. CHECKPOINTS (1, 5, 10, 20)"
echo "-------------------------------"
echo "4. CHECKPOINTS" >> "$RESULTS"

for level in 1 5 10 20; do
    echo -n "   $level parallel: "
    START=$(date +%s%N)
    for i in $(seq 1 $level); do
        python3 runtime/checkpoint/checkpoint.py z-$i runtime/world/snapshots/room.snapshot.json runtime/world/trace/room.seed.jsonl /tmp/s_$i.json /tmp/c_$i.json > /dev/null 2>&1 &
    done
    wait
    END=$(date +%s%N)
    
    t=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
    echo "${t}s"
    echo "$level: ${t}s" >> "$RESULTS"
    rm -f /tmp/s_*.json /tmp/c_*.json
done

echo ""
echo "======================================"
echo "LOAD TEST COMPLETE"
echo "======================================"
echo ""
echo "Results: $RESULTS"
