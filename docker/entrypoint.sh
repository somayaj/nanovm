#!/bin/sh
set -e
case "${1:-}" in
  news)
    exec /opt/agent/run.sh
    ;;
  shell|bash|sh)
    exec /bin/bash
    ;;
  *)
    exec "$@"
    ;;
esac
