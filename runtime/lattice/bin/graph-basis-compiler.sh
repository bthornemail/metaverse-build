#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SEEDS="$ROOT/runtime/lattice/boards/kernel-v1/peers.d/seed.jsonl"
OBS="$ROOT/runtime/lattice/state/peers/observed.jsonl"
GRAPH="$ROOT/runtime/lattice/state/graph/peergraph.json"
BASIS="$ROOT/runtime/lattice/state/graph/basis.json"
PLAN="$ROOT/runtime/lattice/state/plan/connection-plan.json"
TRACE="$ROOT/runtime/lattice/state/traces/discovery.log"
MAX_PEERS="${MAX_PEERS:-1}"

TMP_NODES=$(mktemp)

collect_nodes() {
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    peer=$(printf "%s" "$line" | sed -n 's/.*"peer":"\([^"]*\)".*/\1/p')
    if [ -z "$peer" ]; then
      peer=$(printf "%s" "$line" | sed -n 's/.*"node":"\([^"]*\)".*/\1/p')
    fi
    [ -n "$peer" ] || continue
    addr=$(printf "%s" "$line" | sed -n 's/.*"addr":"\([^"]*\)".*/\1/p')
    mqtt=$(printf "%s" "$line" | sed -n 's/.*"mqtt":\([0-9][0-9]*\).*/\1/p')
    rtt=$(printf "%s" "$line" | sed -n 's/.*"rtt_ms":\([0-9][0-9]*\).*/\1/p')
    printf "%s\t%s\t%s\t%s\n" "$peer" "$addr" "$mqtt" "$rtt"
  done
}

cat "$SEEDS" "$OBS" 2>/dev/null | collect_nodes | sort -u > "$TMP_NODES"

# Build peergraph.json
{
  echo '{'
  echo '  "version": "peergraph-1",'
  echo '  "nodes": ['
  first=1
  while IFS=$'\t' read -r peer addr mqtt rtt; do
    [ -n "$peer" ] || continue
    [ $first -eq 0 ] && printf ',\n'
    first=0
    printf '    {"id":"%s","addr":"%s","caps":["mqtt"],"health":{"ok":true}}' "$peer" "${addr:-0.0.0.0}"
  done < "$TMP_NODES"
  echo
  echo '  ],'
  echo '  "edges": ['
  host=$(head -n 1 "$TMP_NODES" | cut -f1)
  first=1
  while IFS=$'\t' read -r peer addr mqtt rtt; do
    [ -n "$peer" ] || continue
    [ "$peer" = "$host" ] && continue
    [ $first -eq 0 ] && printf ',\n'
    first=0
    printf '    {"a":"%s","b":"%s","kind":"seen","weight":1.0}' "$host" "$peer"
  done < "$TMP_NODES"
  echo
  echo '  ],'
  echo '  "simplices": []'
  echo '}'
} > "$GRAPH"

# Basis selection: choose peers with mqtt port, prefer lower rtt if provided
TMP_SCORE=$(mktemp)
while IFS=$'\t' read -r peer addr mqtt rtt; do
  [ -n "$peer" ] || continue
  if [ -z "$mqtt" ]; then
    continue
  fi
  if [ -z "$rtt" ]; then
    score=1000
  else
    score=$((100000 - rtt))
  fi
  printf "%s\t%s\t%s\n" "$score" "$peer" "$mqtt"
 done < "$TMP_NODES" | sort -nr > "$TMP_SCORE"

{
  echo '{'
  echo '  "version": "basis-1",'
  echo '  "selected": ['
  count=0
  first=1
  while IFS=$'\t' read -r score peer mqtt; do
    [ -n "$peer" ] || continue
    if [ "$count" -ge "$MAX_PEERS" ]; then
      break
    fi
    [ $first -eq 0 ] && printf ',\n'
    first=0
    printf '    {"peer":"%s","transport":"mqtt","lane":"smooth","score":%.2f}' "$peer" "$score"
    count=$((count + 1))
  done < "$TMP_SCORE"
  echo
  echo '  ],'
  echo '  "rejected": []'
  echo '}'
} > "$BASIS"

# Connection plan from basis
{
  echo '{'
  echo '  "version": "plan-1",'
  echo '  "attachments": ['
  first=1
  while IFS= read -r line; do
    peer=$(printf "%s" "$line" | sed -n 's/.*"peer":"\([^"]*\)".*/\1/p')
    [ -n "$peer" ] || continue
    [ $first -eq 0 ] && printf ',\n'
    first=0
    printf '    {"name":"mqtt-%s","kind":"mqtt","peer":"%s","topic":"metaverse/trace","lane":"smooth"}' "$peer" "$peer"
  done < "$BASIS"
  echo
  echo '  ]'
  echo '}'
} > "$PLAN"

# Trace record
 ts=$(date +%s)
 printf '{"t":%s,"type":"basis","graph":"%s","basis":"%s","plan":"%s"}\n' "$ts" "$GRAPH" "$BASIS" "$PLAN" >> "$TRACE"

rm -f "$TMP_NODES" "$TMP_SCORE"
