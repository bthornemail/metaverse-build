# Fan-Out Topology — Single Gate, Multiple Chains

Authority is enforced **once at the root**. All projections are downstream and independent.

Topology:
```
Trace → AuthorityGate →
  Chain A: Sync → RPC → Replay
  Chain B: PubSub (FIFO/MQTT)
  Chain C: UI Stream (HTTP)
```

PASS:
```bash
ID_PREFIX=valid TRACE_INPUT="hello" ./metaverse-build/pipelines/identity-trace-authority-fanout.sh
```

FAIL:
```bash
ID_PREFIX="" TRACE_INPUT="hello" ./metaverse-build/pipelines/identity-trace-authority-fanout.sh
```

Expected:
- FAIL: gate halts, no branch output, no pubsub messages, no UI updates
- PASS: Chain A produces output, PubSub publishes, UI stream updates

Phase 19A adds QoS priority lanes downstream of the single AuthorityGate. QoS affects only projection latency/throughput, never validity. HALT upstream prevents all branches regardless of lane.

Metrics mode:
```bash
METRICS_N=10 METRICS_QOS_SLEEP=0.20 \
  ./metaverse-build/pipelines/fanout/phase19A-run.sh metrics
```
Outputs: `metaverse-build/reports/phase19A-metrics.txt`
