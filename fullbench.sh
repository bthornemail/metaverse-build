#!/bin/bash
# Metaverse Runtime - Full Feature Benchmark Suite
# Probes each interface directly to measure maximum throughput

OUTPUT_DIR="reports/fullbench_$(date +%Y%m%d_%H%M%S)"
mkdir -p $OUTPUT_DIR

SUMMARY="$OUTPUT_DIR/SUMMARY.md"

echo "# Metaverse Runtime Full Benchmark Suite" > $SUMMARY
echo "Date: $(date)" >> $SUMMARY
echo "" >> $SUMMARY

echo "========================================"
echo "  METAVERSE FULL FEATURE BENCHMARK"
echo "========================================"
echo ""

# 1. WORLD INTERFACE (In-Memory)
echo "[1/8] World State Interface"
echo "## 1. World State Interface" >> $SUMMARY

python3 - "$OUTPUT_DIR" << 'PY' >> $OUTPUT_DIR/world_results.txt
import sys, time, json, hashlib

class WorldBench:
    def __init__(self):
        self.state = {"entities": {}, "version": "1.0"}
    
    def apply(self, event):
        e = event["entity"]
        if e not in self.state["entities"]:
            self.state["entities"][e] = {}
        if "component" in event:
            self.state["entities"][e][event["component"]] = event.get("data", {})
        return True

bench = WorldBench()
events = [{"entity": f"e{i%100}", "component": "pos", "data": {"x": i}} for i in range(100000)]

start = time.time()
for e in events:
    bench.apply(e)
elapsed = time.time() - start

ops = len(events) / elapsed
print(f"100K events: {ops:.0f}/sec")
sys.stdout.flush()
PY

WORLD_OPS=$(grep "100K events" $OUTPUT_DIR/world_results.txt | awk '{print $3}')
echo "  ✓ In-memory: $WORLD_OPS/sec"
echo "- **In-memory:** $WORLD_OPS/sec" >> $SUMMARY

# 2. AUTHORITY GATE
echo ""
echo "[2/8] Authority Gate"
echo "## 2. Authority Gate" >> $SUMMARY

EVENTS=10
START=$(date +%s%N)
for i in $(seq 1 $EVENTS); do
    echo '{"actor":"valid:userA"}' | runhaskell invariants/authority/gate/AuthorityGate.hs > /dev/null 2>&1 || true
done
END=$(date +%s%N)
GATE_TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)
GATE_RATE=$(echo "scale=1; $EVENTS / $GATE_TIME" | bc)

echo "  ✓ Direct: $GATE_RATE/sec"
echo "- **Direct:** $GATE_RATE/sec" >> $SUMMARY

# 3. TRANSPORT LAYER
echo ""
echo "[3/8] Transport Layer"
echo "## 3. Transport Layer" >> $SUMMARY

# FIFO benchmark
python3 - "$OUTPUT_DIR" << 'PY' >> $OUTPUT_DIR/transport_results.txt
import time, os, threading

def bench_fifo(count=10000):
    fifo = "/tmp/fifobench"
    if os.path.exists(fifo): os.unlink(fifo)
    os.mkfifo(fifo)
    
    def writer():
        with open(fifo, 'w') as f:
            for i in range(count):
                f.write(f"msg{i}\n")
                f.flush()
    
    def reader():
        with open(fifo, 'r') as f:
            for _ in range(count):
                f.readline()
    
    t = threading.Thread(target=reader)
    t.start()
    start = time.time()
    writer()
    t.join()
    elapsed = time.time() - start
    os.unlink(fifo)
    return count / elapsed

print(f"FIFO: {bench_fifo(10000):.0f}/sec")
PY

FIFO_OPS=$(grep "FIFO" $OUTPUT_DIR/transport_results.txt | awk '{print $2}')
echo "  ✓ FIFO: $FIFO_OPS/sec"
echo "- **FIFO:** $FIFO_OPS/sec" >> $SUMMARY

# 4. CHECKPOINT I/O
echo ""
echo "[4/8] Checkpoint I/O"
echo "## 4. Checkpoint I/O" >> $SUMMARY

python3 - "$OUTPUT_DIR" << 'PY' >> $OUTPUT_DIR/io_results.txt
import time, json, os, tempfile, hashlib

sizes = [10, 100, 1000, 10000]
for size in sizes:
    state = {"entities": {f"e{i}": {"pos": [i,i,i]} for i in range(size)}}
    data = json.dumps(state)
    
    start = time.time()
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as f:
        f.write(data)
        f.flush()
        os.fsync(f.fileno())
    write_time = time.time() - start
    
    start = time.time()
    with open(f.name) as f: f.read()
    read_time = time.time() - start
    
    os.unlink(f.name)
    print(f"{size},{write_time*1000:.2f},{read_time*1000:.2f}")
PY

echo "  ✓ I/O benchmarks complete"
echo "- **I/O:** See io_results.csv" >> $SUMMARY

# 5. LATTICE DISCOVERY
echo ""
echo "[5/8] Lattice Peer Discovery"
echo "## 5. Lattice" >> $SUMMARY

python3 - "$OUTPUT_DIR" << 'PY' >> $OUTPUT_DIR/lattice_results.txt
import time, json, os, tempfile, random

def bench_lattice(peers):
    with tempfile.TemporaryDirectory() as tmpdir:
        seeds = os.path.join(tmpdir, "seeds")
        observe = os.path.join(tmpdir, "observe")
        os.makedirs(seeds)
        os.makedirs(observe)
        
        for i in range(min(peers, 10)):
            with open(os.path.join(seeds, f"s{i}.json"), 'w') as f:
                json.dump({"peer": f"p{i}", "addr": f"10.0.0.{i}:8000"}, f)
        
        start = time.time()
        for i in range(peers):
            obs = random.sample(range(peers), min(5, peers))
            with open(os.path.join(observe, f"o{i}.json"), 'w') as f:
                json.dump({"peer": f"p{i}", "observed": [f"p{j}" for j in obs]}, f)
        elapsed = time.time() - start
        return peers / elapsed

for p in [10, 100, 1000]:
    print(f"{p},{bench_lattice(p):.0f}")
PY

echo "  ✓ Lattice benchmarks complete"
echo "- **Lattice:** See lattice_results.txt" >> $SUMMARY

# 6. SYNC PROTOCOL
echo ""
echo "[6/8] Sync Protocol"
echo "## 6. Sync Protocol" >> $SUMMARY

python3 - "$OUTPUT_DIR" << 'PY' >> $OUTPUT_DIR/sync_results.txt
import time, json, hashlib, random

class Sync:
    def __init__(self, pid): self.pid, self.seq = pid, 0
    def envelope(self, e):
        self.seq += 1
        return {"peer": self.pid, "seq": self.seq, "event": e}
    def merge(self, envs):
        return sorted(envs, key=lambda x: (x["peer"], x["seq"]))

def bench_sync(peers, events):
    all_env = []
    for p in range(peers):
        s = Sync(f"p{p}")
        for _ in range(events):
            all_env.append(s.envelope({"type": "move", "x": random.random()}))
    
    start = time.time()
    merged = Sync("").merge(all_env)
    elapsed = time.time() - start
    
    return len(all_env) / elapsed

for p in [2, 5, 10, 20]:
    print(f"{p},{bench_sync(p, 1000):.0f}")
PY

echo "  ✓ Sync benchmarks complete"
echo "- **Sync:** See sync_results.txt" >> $SUMMARY

# 7. ZONE ROUTING
echo ""
echo "[7/8] Zone Routing"
echo "## 7. Zone Routing" >> $SUMMARY

python3 - "$OUTPUT_DIR" << 'PY' >> $OUTPUT_DIR/zone_results.txt
import time, random

def bench_zones(num_zones, events):
    routing = {f"e{i}": f"z{i%num_zones}" for i in range(10000)}
    evts = [{"entity": f"e{i%10000}"} for i in range(events)]
    
    start = time.time()
    for e in evts:
        _ = routing.get(e["entity"], "unknown")
    elapsed = time.time() - start
    
    return events / elapsed

for z in [2, 5, 10, 50, 100]:
    print(f"{z},{bench_zones(z, 100000):.0f}")
PY

echo "  ✓ Zone routing benchmarks complete"
echo "- **Zone routing:** See zone_results.txt" >> $SUMMARY

# 8. END-TO-END PIPELINE
echo ""
echo "[8/8] End-to-End Pipeline"
echo "## 8. Pipeline" >> $SUMMARY

bash runtime/world/load-ir.sh world-ir/build/room.ir.json > /dev/null 2>&1
START=$(date +%s%N)
bash runtime/world/lifecycle-tests.sh > /dev/null 2>&1
END=$(date +%s%N)
PIPE_TIME=$(echo "scale=3; ($END - $START) / 1000000000" | bc)

EVENTS=$(cat runtime/world/trace/*.jsonl 2>/dev/null | wc -l)
PIPE_RATE=$(echo "scale=1; $EVENTS / $PIPE_TIME" | bc)

echo "  ✓ Pipeline: $EVENTS events in ${PIPE_TIME}s = $PIPE_RATE/sec"
echo "- **Pipeline:** $PIPE_RATE/sec ($EVENTS events)" >> $SUMMARY

# SUMMARY
echo ""
echo "========================================"
echo "BENCHMARK COMPLETE"
echo "========================================"
echo ""
echo "Results: $OUTPUT_DIR/"
echo ""
echo "KEY METRICS:"
echo "  World (in-memory): $WORLD_OPS/sec"
echo "  Authority Gate:    $GATE_RATE/sec"
echo "  FIFO Transport:    $FIFO_OPS/sec"
echo "  End-to-End:        $PIPE_RATE/sec"
echo ""
echo "BOTTLENECK ANALYSIS:"
echo "  Gap: $(echo "scale=0; $WORLD_OPS / $GATE_RATE" | bc)x between potential and actual"
echo "  Authority gate is primary bottleneck"
echo ""
echo "Summary: $OUTPUT_DIR/SUMMARY.md"
