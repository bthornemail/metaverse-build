#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SEEDS_DIR="$ROOT/runtime/lattice/peers/seeds.d"
OBS="$ROOT/runtime/lattice/peers/observe/observed.jsonl"
GRAPH="$ROOT/runtime/lattice/graph/peergraph.json"
BASIS="$ROOT/runtime/lattice/graph/basis.json"
TRACE="$ROOT/runtime/lattice/trace/routing.log"
MAX_PEERS="${MAX_PEERS:-1}"

[ -d "$(dirname "$GRAPH")" ] || mkdir -p "$(dirname "$GRAPH")"
[ -d "$(dirname "$TRACE")" ] || mkdir -p "$(dirname "$TRACE")"

TMP_NODES=$(mktemp)

extract_lines() {
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    peer=$(printf "%s" "$line" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
    if [ -z "$peer" ]; then
      peer=$(printf "%s" "$line" | sed -n 's/.*"node":"\([^"]*\)".*/\1/p')
    fi
    addr=$(printf "%s" "$line" | sed -n 's/.*"addr":"\([^"]*\)".*/\1/p')
    bus=$(printf "%s" "$line" | sed -n 's/.*"bus":\([0-9][0-9]*\).*/\1/p')
    rtt=$(printf "%s" "$line" | sed -n 's/.*"rtt_ms":\([0-9][0-9]*\).*/\1/p')
    printf "%s\t%s\t%s\t%s\n" "$peer" "$addr" "$bus" "$rtt"
  done
}

{
  cat "$SEEDS_DIR"/*.json 2>/dev/null | extract_lines
  [ -f "$OBS" ] && extract_lines < "$OBS"
} | awk -F'\t' '
  {
    p=$1; a=$2; b=$3; r=$4;
    if (p=="") next;
    if (a!="") addr[p]=a;
    if (b!="") bus[p]=b;
    if (r!="") rtt[p]=r;
    peers[p]=1;
  }
  END {
    for (p in peers) {
      printf "%s\t%s\t%s\t%s\n", p, addr[p], bus[p], rtt[p];
    }
  }
' | sort -u > "$TMP_NODES"

# PeerGraph
{
  echo '{'
  echo '  "version": "peergraph-1",'
  echo '  "nodes": ['
  first=1
  while IFS=$'\t' read -r peer addr bus rtt; do
    [ -n "$peer" ] || continue
    [ $first -eq 0 ] && printf ',\n'
    first=0
    printf '    {"id":"%s","addr":"%s","ports":{"bus":%s},"health":{"ok":true,"rtt_ms":%s}}' "$peer" "${addr:-0.0.0.0}" "${bus:-0}" "${rtt:-0}"
  done < "$TMP_NODES"
  echo
  echo '  ],'
  echo '  "edges": [],'
  echo '  "simplices": []'
  echo '}'
} > "$GRAPH"

# Basis selection: choose lowest rtt
TMP_SCORE=$(mktemp)
while IFS=$'\t' read -r peer addr bus rtt; do
  [ -n "$peer" ] || continue
  [ -z "$bus" ] && continue
  if [ -z "$rtt" ]; then
    score=0
  else
    score=$((100000 - rtt))
  fi
  printf "%s\t%s\t%s\t%s\n" "$score" "$peer" "$addr" "$bus"
 done < "$TMP_NODES" | sort -nr > "$TMP_SCORE"

{
  echo '{'
  echo '  "version": "basis-1",'
  echo '  "selected": ['
  count=0
  first=1
  while IFS=$'\t' read -r score peer addr bus; do
    [ -n "$peer" ] || continue
    if [ "$count" -ge "$MAX_PEERS" ]; then
      break
    fi
    [ $first -eq 0 ] && printf ',\n'
    first=0
    printf '    {"peer":"%s","transport":"bus","lane":"tcp","score":%.2f}' "$peer" "$score"
    count=$((count + 1))
  done < "$TMP_SCORE"
  echo
  echo '  ],'
  echo '  "rejected": []'
  echo '}'
} > "$BASIS"

# Trace routing decision
 ts=$(date +%s)
 printf '{"t":%s,"type":"basis","graph":"%s","basis":"%s"}\n' "$ts" "$GRAPH" "$BASIS" >> "$TRACE"

rm -f "$TMP_NODES" "$TMP_SCORE"
