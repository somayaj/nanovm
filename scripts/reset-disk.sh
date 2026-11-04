#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM_DIR="${1:-${ROOT}/.nanovm}"
BASE="${VM_DIR}/alpine-base.qcow2"
DISK="${VM_DIR}/alpine-disk.qcow2"

NANOVM_IMAGE="${NANOVM_IMAGE:-alpine-3.24.2-aarch64-cloudinit-r2.qcow2}" \
  ./scripts/ensure-image.sh "$VM_DIR"

cp -f "$BASE" "$DISK"
echo "Reset guest disk: ${DISK}"
