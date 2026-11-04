#!/usr/bin/env bash
set -euo pipefail

PIDFILE="${1:?pidfile}"
SSH_PORT="${2:?port}"
VM_DIR="${3:?vm dir}"

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "VM: running (pid $(cat "$PIDFILE"))"
else
  echo "VM: stopped"
fi

if ssh -p "$SSH_PORT" -i "${VM_DIR}/id_ed25519" \
  -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  alpine@127.0.0.1 'hostname && uname -a' 2>/dev/null; then
  echo "SSH: ok"
else
  echo "SSH: not ready (cloud-init may still be running)"
fi
