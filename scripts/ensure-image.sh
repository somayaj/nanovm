#!/usr/bin/env bash
set -euo pipefail
VM_DIR="${1:?vm dir}"
BASE="${VM_DIR}/alpine-base.qcow2"
DISK="${VM_DIR}/alpine-disk.qcow2"
IMAGE="${NANOVM_IMAGE:-alpine-3.24.2-aarch64-cloudinit-r2.qcow2}"
URL="${NANOVM_IMAGE_URL:-https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/cloud/${IMAGE}}"

mkdir -p "$VM_DIR"

if [[ ! -f "$BASE" ]]; then
  TMP="${BASE}.partial"
  echo "Downloading ${URL} ..."
  curl -fL --progress-bar -o "$TMP" "$URL"
  mv "$TMP" "$BASE"
  echo "Saved base image ${BASE}"
else
  echo "Base image present: ${BASE}"
fi

if [[ ! -f "$DISK" ]]; then
  cp -f "$BASE" "$DISK"
  echo "Created guest disk from base: ${DISK}"
fi
