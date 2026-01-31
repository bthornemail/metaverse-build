#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-fast}"

case "$MODE" in
  fast)
    cat
    ;;
  smooth)
    pv -q -L "${QOS_BPS:-50k}"
    ;;
  slow)
    awk '{ print; fflush(); system("sleep " (ENVIRON["QOS_SLEEP"] ? ENVIRON["QOS_SLEEP"] : "0.05")) }'
    ;;
  *)
    echo "Unknown QoS mode: $MODE" >&2
    exit 2
    ;;
 esac
