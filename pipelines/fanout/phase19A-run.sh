#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FANOUT="$ROOT/pipelines/identity-trace-authority-fanout.sh"
REPORT="$ROOT/reports/phase19A-transcript.txt"

stamp() {
  awk '{ cmd="date +%s.%N"; cmd|getline t; close(cmd); print t, $0; fflush(); }'
}

run_pass() {
  local label="$1"
  local qos_sleep="$2"
  rm -f "$ROOT/pipelines/pubsub/pubsub.fifo" "$ROOT/pipelines/ui/ui.stream"
  rm -f /tmp/phase19A-pubsub.out /tmp/phase19A-chainA.out /tmp/phase19A-ui.out

  bash "$ROOT/pipelines/pubsub/subscribe.sh" | stamp > /tmp/phase19A-pubsub.out 2>&1 &
  SUB_PID=$!

  : > /tmp/phase19A-chainA.out
  : > /tmp/phase19A-ui.out

  if [ -n "$qos_sleep" ]; then
    QOS_SLEEP="$qos_sleep" ID_PREFIX=valid TRACE_INPUT="hello" bash "$FANOUT" | stamp > /tmp/phase19A-chainA.out 2>&1
  else
    ID_PREFIX=valid TRACE_INPUT="hello" bash "$FANOUT" | stamp > /tmp/phase19A-chainA.out 2>&1
  fi

  # wait for subscriber to exit naturally
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if kill -0 "$SUB_PID" >/dev/null 2>&1; then
      sleep 0.1
    else
      break
    fi
  done
  if kill -0 "$SUB_PID" >/dev/null 2>&1; then
    kill "$SUB_PID" >/dev/null 2>&1 || true
  fi
  wait "$SUB_PID" >/dev/null 2>&1 || true

  if [ -f "$ROOT/pipelines/ui/ui.stream" ]; then
    cat "$ROOT/pipelines/ui/ui.stream" | stamp > /tmp/phase19A-ui.out 2>&1
  fi

  echo "### $label"
  echo "Chain A (timestamped):"
  sed -n '1,5p' /tmp/phase19A-chainA.out
  echo
  echo "PubSub (timestamped):"
  sed -n '1,5p' /tmp/phase19A-pubsub.out
  echo
  echo "UI stream (timestamped):"
  sed -n '1,5p' /tmp/phase19A-ui.out
  echo
}

run_fail() {
  echo "### FAIL"
  set +e
  ID_PREFIX="" TRACE_INPUT="hello" bash "$FANOUT" 2>&1
  echo "Exit code: $?"
  set -e
  echo
}

median_from_file() {
  local file="$1"
  local tmp=""
  if [ "$file" = "/dev/stdin" ] || [ "$file" = "-" ]; then
    tmp="$(mktemp)"
    cat > "$tmp"
    file="$tmp"
  fi
  local count
  count=$(wc -l < "$file" | tr -d ' ')
  if [ "$count" -eq 0 ]; then
    [ -n "$tmp" ] && rm -f "$tmp"
    echo "n/a"
    return
  fi
  if [ $((count % 2)) -eq 1 ]; then
    local k=$(( (count + 1) / 2 ))
    local out
    out=$(sed -n "${k}p" "$file")
    [ -n "$tmp" ] && rm -f "$tmp"
    echo "$out"
  else
    local k1=$(( count / 2 ))
    local k2=$(( k1 + 1 ))
    local out
    out=$(awk -v k1="$k1" -v k2="$k2" 'NR==k1{a=$1} NR==k2{b=$1} END{if (a==""||b=="") print "n/a"; else printf "%.9f\n", (a+b)/2 }' "$file")
    [ -n "$tmp" ] && rm -f "$tmp"
    echo "$out"
  fi
}

metrics_mode() {
  local runs="${METRICS_N:-10}"
  local qos_sleep="${METRICS_QOS_SLEEP:-}"
  local tmpdir
  tmpdir="$(mktemp -d)"
  local chain_d="$tmpdir/chain.delays"
  local pub_d="$tmpdir/pub.delays"
  local ui_d="$tmpdir/ui.delays"
  : > "$chain_d"
  : > "$pub_d"
  : > "$ui_d"

  for i in $(seq 1 "$runs"); do
    rm -f "$ROOT/pipelines/pubsub/pubsub.fifo" "$ROOT/pipelines/ui/ui.stream"
    rm -f /tmp/phase19A-metrics-pub.out /tmp/phase19A-metrics-chain.out /tmp/phase19A-metrics-ui.out

    mkdir -p "$ROOT/pipelines/fanout" "$ROOT/pipelines/ui"
    : > "$ROOT/pipelines/fanout/fanout.chainA.out"
    : > "$ROOT/pipelines/ui/ui.stream"

    tail -n +1 -F "$ROOT/pipelines/fanout/fanout.chainA.out" | stamp > /tmp/phase19A-metrics-chain.out 2>&1 &
    CHAIN_PID=$!
    tail -n +1 -F "$ROOT/pipelines/ui/ui.stream" | stamp > /tmp/phase19A-metrics-ui.out 2>&1 &
    UI_PID=$!
    bash "$ROOT/pipelines/pubsub/subscribe.sh" | stamp > /tmp/phase19A-metrics-pub.out 2>&1 &
    SUB_PID=$!

    if [ -n "$qos_sleep" ]; then
      QOS_SLEEP="$qos_sleep" ID_PREFIX=valid TRACE_INPUT="hello" bash "$FANOUT" | stamp > /tmp/phase19A-metrics-chain.out 2>&1
    else
      ID_PREFIX=valid TRACE_INPUT="hello" bash "$FANOUT" | stamp > /tmp/phase19A-metrics-chain.out 2>&1
    fi

    sleep 0.3
    kill "$SUB_PID" "$CHAIN_PID" "$UI_PID" >/dev/null 2>&1 || true

    if [ ! -s /tmp/phase19A-metrics-chain.out ] && [ -f "$ROOT/pipelines/fanout/fanout.chainA.out" ]; then
      cat "$ROOT/pipelines/fanout/fanout.chainA.out" | stamp > /tmp/phase19A-metrics-chain.out 2>&1
    fi
    if [ ! -s /tmp/phase19A-metrics-ui.out ] && [ -f "$ROOT/pipelines/ui/ui.stream" ]; then
      cat "$ROOT/pipelines/ui/ui.stream" | stamp > /tmp/phase19A-metrics-ui.out 2>&1
    fi

    local t_chain t_pub t_ui t_min
    t_chain=$(awk 'NR==1{print $1}' /tmp/phase19A-metrics-chain.out || true)
    t_pub=$(awk 'NR==1{print $1}' /tmp/phase19A-metrics-pub.out || true)
    t_ui=$(awk 'NR==1{print $1}' /tmp/phase19A-metrics-ui.out || true)

    t_min=$(printf "%s\n%s\n%s\n" "$t_chain" "$t_pub" "$t_ui" | awk 'NF{if(min==""||$1<min)min=$1} END{print min}')
    if [ -n "$t_min" ]; then
      if [ -n "$t_chain" ]; then awk -v a="$t_chain" -v b="$t_min" 'BEGIN{printf "%.9f\n", a-b}' >> "$chain_d"; fi
      if [ -n "$t_pub" ]; then awk -v a="$t_pub" -v b="$t_min" 'BEGIN{printf "%.9f\n", a-b}' >> "$pub_d"; fi
      if [ -n "$t_ui" ]; then awk -v a="$t_ui" -v b="$t_min" 'BEGIN{printf "%.9f\n", a-b}' >> "$ui_d"; fi
    fi
  done

  local med_chain med_pub med_ui
  med_chain=$(sort -n "$chain_d" | median_from_file /dev/stdin)
  med_pub=$(sort -n "$pub_d" | median_from_file /dev/stdin)
  med_ui=$(sort -n "$ui_d" | median_from_file /dev/stdin)

  {
    echo "# Phase 19A — Metrics Mode"
    echo "Date: $(date -Iseconds)"
    echo "Host: $(hostname)"
    echo "Runs: $runs"
    if [ -n "$qos_sleep" ]; then
      echo "QOS_SLEEP: $qos_sleep"
    fi
    echo
    echo "Median delay (seconds) relative to earliest lane:"
    echo "Chain A: $med_chain"
    echo "PubSub:  $med_pub"
    echo "UI:      $med_ui"
  } | tee "$ROOT/reports/phase19A-metrics.txt"

  rm -rf "$tmpdir"
}

if [ "${1:-}" = "metrics" ]; then
  metrics_mode
  exit 0
fi

{
  echo "# Phase 19A — Rate Limits & Priority Lanes Transcript"
  echo "Date: $(date -Iseconds)"
  echo "Host: $(hostname)"
  echo
  echo "## PASS (default QoS)"
  run_pass "PASS (default QoS)" ""
  echo "## PASS (slow chain)"
  run_pass "PASS (slow chain, QOS_SLEEP=0.20)" "0.20"
  echo "## FAIL (HALT)"
  run_fail
} > "$REPORT"

sed -n '1,200p' "$REPORT"
