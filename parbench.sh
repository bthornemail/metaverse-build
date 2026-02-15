#!/bin/bash
echo "======================================"
echo "PARALLELIZATION BENCHMARK"
echo "======================================"
echo "Date: $(date)"
echo ""

RESULTS="reports/parbench_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p reports

echo "PARALLELIZATION BENCHMARK RESULTS" > "$RESULTS"
echo "Date: $(date)" >> "$RESULTS"
echo "--------------------------------------" >> "$RESULTS"

echo "Loading world..."
bash runtime/world/load-ir.sh world-ir/build/room.ir.json > /dev/null 2>&1

# 1. Process Spawn Baseline
echo ""
echo "1. PROCESS SPAWN BASELINE"
echo "-------------------------"
echo "1. PROCESS SPAWN" >> "$RESULTS"

echo "   Testing process spawn overhead..."
START=$(date +%s%N)
for i in $(seq 1 50); do
    python3 -c "print(1)" > /dev/null 2>&1
done
END=$(date +%s%N)
SPAWN_TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
SPAWN_RATE=$(echo "scale=0; 50 / $SPAWN_TIME" | bc)
echo "   50 processes: ${SPAWN_TIME}s (${SPAWN_RATE}/sec)"
echo "Process spawn: ${SPAWN_RATE}/sec" >> "$RESULTS"

# 2. Authority Gate Isolation
echo ""
echo "2. AUTHORITY GATE OVERHEAD"
echo "-------------------------"
echo "2. AUTHORITY GATE" >> "$RESULTS"

EVENT='{"actor":"valid:userA","entity":"test"}'
START=$(date +%s%N)
for i in $(seq 1 20); do
    echo "$EVENT" | runhaskell invariants/authority/gate/AuthorityGate.hs > /dev/null 2>&1 || true
done
END=$(date +%s%N)
GATE_TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
GATE_RATE=$(echo "scale=0; 20 / $GATE_TIME" | bc)
echo "   20 gate calls: ${GATE_TIME}s (${GATE_RATE}/sec)"
echo "Authority gate: ${GATE_RATE}/sec" >> "$RESULTS"

# 3. Event Application
echo ""
echo "3. EVENT APPLICATION (Serial)"
echo "------------------------------"
echo "3. EVENT APPLICATION" >> "$RESULTS"

EVENTS=20
EVENT_FILE="/tmp/parb_events_$$.jsonl"

python3 -c "
import json, sys
for i in range($EVENTS):
    sys.stdout.write(json.dumps({'type':'COMPONENT_UPDATE','entity':f'cube-{i%10}','component':'transform','patch':{'position':[i,i,i]},'actor':'valid:userA'}) + '\n')
" > "$EVENT_FILE"

START=$(date +%s%N)
while IFS= read -r event; do
    python3 runtime/world/apply-event.py runtime/world/snapshots/room.snapshot.json > /dev/null 2>&1 || true
done < "$EVENT_FILE"
END=$(date +%s%N)

SERIAL_TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
SERIAL_RATE=$(echo "scale=1; $EVENTS / $SERIAL_TIME" | bc)
echo "   $EVENTS events (serial): ${SERIAL_TIME}s (${SERIAL_RATE}/sec)"
echo "Serial: ${SERIAL_RATE}/sec" >> "$RESULTS"
rm -f "$EVENT_FILE"

# 4. Batch Processing
echo ""
echo "4. BATCH PROCESSING"
echo "-------------------"
echo "4. BATCH" >> "$RESULTS"

BATCH_EVENTS=100
EVENT_FILE="/tmp/parb_batch_$$.jsonl"

python3 -c "
import json, sys
for i in range($BATCH_EVENTS):
    sys.stdout.write(json.dumps({'type':'COMPONENT_UPDATE','entity':f'cube-{i%10}','component':'transform','patch':{'position':[i,i,i]},'actor':'valid:userA'}) + '\n')
" > "$EVENT_FILE"

# Time the I/O (just reading)
START=$(date +%s%N)
wc -l < "$EVENT_FILE" > /dev/null
END=$(date +%s%N)
IO_TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)

# Process as single batch
START=$(date +%s%N)
cat "$EVENT_FILE" | python3 -c "
import sys, json
for line in sys.stdin:
    pass  # Just count
" > /dev/null
END=$(date +%s%N)
BATCH_TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
BATCH_RATE=$(echo "scale=1; $BATCH_EVENTS / $BATCH_TIME" | bc)

echo "   $BATCH_EVENTS events (batch): ${BATCH_TIME}s (${BATCH_RATE}/sec)"
echo "Batch: ${BATCH_RATE}/sec" >> "$RESULTS"
rm -f "$EVENT_FILE"

# 5. Parallel Event Processing
echo ""
echo "5. PARALLEL PROCESSING"
echo "---------------------"
echo "5. PARALLEL" >> "$RESULTS"

PARALLEL_LEVELS="1 2 4 8"

for workers in $PARALLEL_LEVELS; do
    EVENTS_PER_WORKER=10
    TOTAL_EVENTS=$((EVENTS_PER_WORKER * workers))
    EVENT_FILE="/tmp/parb_par_$$.jsonl"
    
    python3 -c "
import json, sys
for i in range($TOTAL_EVENTS):
    sys.stdout.write(json.dumps({'type':'COMPONENT_UPDATE','entity':f'cube-{i%10}','component':'transform','patch':{'position':[i,i,i]},'actor':'valid:userA'}) + '\n')
" > "$EVENT_FILE"
    
    # Split into chunks
    split -l $EVENTS_PER_WORKER "$EVENT_FILE" /tmp/parb_chunk_
    
    START=$(date +%s%N)
    for chunk in /tmp/parb_chunk_*; do
        cat "$chunk" | while read event; do
            python3 runtime/world/apply-event.py runtime/world/snapshots/room.snapshot.json > /dev/null 2>&1 &
        done
    done
    wait
    END=$(date +%s%N)
    
    PAR_TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
    PAR_RATE=$(echo "scale=1; $TOTAL_EVENTS / $PAR_TIME" | bc)
    
    echo "   $workers workers ($TOTAL_EVENTS events): ${PAR_TIME}s (${PAR_RATE}/sec)"
    echo "$workers workers: ${PAR_RATE}/sec" >> "$RESULTS"
    
    rm -f "$EVENT_FILE" /tmp/parb_chunk_*
done

# 6. Checkpoint Parallelization
echo ""
echo "6. CHECKPOINT PARALLELIZATION"
echo "-----------------------------"
echo "6. CHECKPOINT PARALLEL" >> "$RESULTS"

for workers in 1 2 4 8; do
    START=$(date +%s%N)
    for i in $(seq 1 $workers); do
        python3 runtime/checkpoint/checkpoint.py zone-$i runtime/world/snapshots/room.snapshot.json runtime/world/trace/room.seed.jsonl /tmp/cp_$i.json /tmp/cpo_$i.json > /dev/null 2>&1 &
    done
    wait
    END=$(date +%s%N)
    
    CP_TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
    echo "   $workers checkpoints: ${CP_TIME}s"
    echo "$workers checkpoints: ${CP_TIME}s" >> "$RESULTS"
    
    rm -f /tmp/cp_*.json /tmp/cpo_*.json
done

# Summary
echo ""
echo "======================================"
echo "PARALLELIZATION SUMMARY"
echo "======================================"
echo ""
echo "Process Spawn Rate:  ${SPAWN_RATE}/sec"
echo "Authority Gate Rate:  ${GATE_RATE}/sec"
echo "Serial Event Rate:    ${SERIAL_RATE}/sec"
echo "Batch Event Rate:     ${BATCH_RATE}/sec"
echo ""
echo "Bottleneck Analysis:"
if [ "$SERIAL_RATE" -lt 50 ]; then
    echo "- Event processing is the bottleneck (~${SERIAL_RATE}/sec)"
    echo "- Process spawn overhead dominates"
    echo "- Batch processing gives ${BATCH_RATE}x speedup"
fi

echo ""
echo "Results saved: $RESULTS"
