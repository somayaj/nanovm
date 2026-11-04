#!/usr/bin/env bash
# True if agents/<id>/manifest.yaml declares a cursor: block (Composer on host).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AGENT="${1:?agent id}"
MF="${ROOT}/agents/${AGENT}/manifest.yaml"
[[ -f "$MF" ]] && grep -qE '^cursor:' "$MF"
