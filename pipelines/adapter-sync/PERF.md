# Phase 16B — Backpressure & Performance Probes

## Environment
- Date: 2026-01-31T08:43:34.816548
- Host: TOSHIBA-PORTEGE-Z30t-C
- Shell: /bin/bash
- pv installed (yes/no): yes

## Commands Run
1) Throughput (PASS path)
```
ID_PREFIX=valid TRACE_INPUT="hello" \
  sh metaverse-build/runtime/trace/sources/run.sh world out | \
  runghc -i"metaverse-build/invariants/authority" metaverse-build/invariants/authority/gate/AuthorityGate.hs | \
  pv -f -t -i 0.5 -rab | \
  sh metaverse-build/pipelines/adapter-sync/run.sh > /dev/null
```

2) Backpressure (slow adapter)
```
ID_PREFIX=valid TRACE_INPUT="hello" \
  sh metaverse-build/runtime/trace/sources/run.sh world out | \
  runghc -i"metaverse-build/invariants/authority" metaverse-build/invariants/authority/gate/AuthorityGate.hs | \
  pv -f -t -i 0.5 -L 10k | \
  sh -c 'sleep 0.05; cat' | \
  sh metaverse-build/pipelines/adapter-sync/run.sh > /dev/null
```

3) HALT cost (FAIL path)
```
time ID_PREFIX="" TRACE_INPUT="hello" \
  sh metaverse-build/runtime/trace/sources/run.sh world out | \
  runghc -i"metaverse-build/invariants/authority" metaverse-build/invariants/authority/gate/AuthorityGate.hs > /dev/null
```

4) Burst handling
```
seq 1 1000 | awk '{print "trace-" $1}' | \
  runghc -i"metaverse-build/invariants/authority" metaverse-build/invariants/authority/gate/AuthorityGate.hs | \
  pv -f -t -i 0.5 -l | \
  sh metaverse-build/pipelines/adapter-sync/run.sh > /dev/null
```

## Observations
- Throughput: see probe output
- Backpressure: see probe output
- HALT cost: see probe output
- Burst handling: see probe output

## Notes
- Raw probe output:

```
== Probe 1: Throughput (PASS path) ==
5.00  B 0:00:00 [13.0  B/s] [13.0  B/s]
== Probe 2: Backpressure (slow adapter) ==
0:00:00
== Probe 3: HALT cost (FAIL path) ==
HALT: InvalidSchemaPrefix

real	0m0.340s
user	0m0.253s
sys	0m0.069s
== Probe 4: Burst handling ==
0:00:00
```

- PV metrics (parsed):

```
5.00  B 0:00:00 [13.0  B/s] [13.0  B/s]
```
 
- Notes: Short-lived probes may emit limited pv lines; increase payload size for richer metrics.
