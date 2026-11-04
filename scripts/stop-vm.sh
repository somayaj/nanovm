#!/usr/bin/env bash
set -euo pipefail

PIDFILE="${1:?pidfile}"

if [[ ! -f "$PIDFILE" ]]; then
  echo "No pidfile; VM not running?"
  exit 0
fi

PID=$(cat "$PIDFILE")
if kill -0 "$PID" 2>/dev/null; then
  kill "$PID"
  echo "Stopped VM (pid $PID)"
else
  echo "Stale pidfile (pid $PID not running)"
fi
rm -f "$PIDFILE"
