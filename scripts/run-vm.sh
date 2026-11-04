#!/usr/bin/env bash
set -euo pipefail

VM_DIR="${1:?vm dir}"
DISK="${2:?disk}"
SEED="${3:?seed}"
PIDFILE="${4:?pidfile}"
SSH_PORT="${5:?ssh port}"

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "VM already running (pid $(cat "$PIDFILE"))"
  exit 0
fi

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH}"

QEMU="qemu-system-aarch64"
if ! command -v "$QEMU" >/dev/null; then
  echo "qemu-system-aarch64 not found (brew install qemu)" >&2
  exit 1
fi

mkdir -p "$VM_DIR"

QEMU_SHARE="${QEMU_SHARE:-/opt/homebrew/share/qemu}"
UEFI_CODE="${QEMU_SHARE}/edk2-aarch64-code.fd"

if [[ ! -f "$UEFI_CODE" ]]; then
  echo "Missing UEFI firmware: $UEFI_CODE" >&2
  exit 1
fi

ACCEL=(-accel hvf)
if ! "$QEMU" -accel help 2>&1 | grep -q hvf; then
  ACCEL=()
fi

# NoCloud: CIDATA seed as virtio block (Alpine/no cloud-init docs).
"$QEMU" \
  -name nanovm \
  -machine virt,highmem=on \
  -cpu host \
  "${ACCEL[@]}" \
  -bios "$UEFI_CODE" \
  -m 512 \
  -smp 2 \
  -drive "file=${DISK},if=none,id=hd0,format=qcow2,cache=writethrough" \
  -device virtio-blk-pci,drive=hd0 \
  -drive "file=${SEED},if=none,id=cidata,format=raw,readonly=on" \
  -device virtio-blk-pci,drive=cidata \
  -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22" \
  -device virtio-net-pci,netdev=net0 \
  -display none \
  -daemonize \
  -pidfile "$PIDFILE"

echo "Started nanovm (pid $(cat "$PIDFILE"))"
echo "SSH on 127.0.0.1:${SSH_PORT} — wait for cloud-init (~30-120s), then: make ssh"
