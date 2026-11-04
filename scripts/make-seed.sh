#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VM_DIR="${1:?vm dir}"
SEED="${2:?seed iso path}"
CLOUD_DIR="${VM_DIR}/cloud-init"
ENV_FILE="${ROOT}/.env"

mkdir -p "$CLOUD_DIR"

KEY="${VM_DIR}/id_ed25519"
if [[ ! -f "$KEY" ]]; then
  ssh-keygen -t ed25519 -f "$KEY" -N "" -C "nanovm-agent"
fi

PUB=$(cat "${KEY}.pub")

SLACK_WEBHOOK_URL=""
NANOVM_TZ="America/Chicago"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

INSTANCE_ID="nanovm-$(date +%Y%m%d%H%M%S)"
echo "$INSTANCE_ID" > "${VM_DIR}/instance-id"

cat > "${CLOUD_DIR}/meta-data" <<EOF
instance-id: ${INSTANCE_ID}
local-hostname: nanovm
EOF

# Keep user-data minimal and valid YAML (no embedded scripts — use make deploy-agent).
cat > "${CLOUD_DIR}/user-data" <<EOF
#cloud-config
hostname: nanovm
manage_etc_hosts: true
ssh_pwauth: false
users:
  - default
  - name: alpine
    gecos: Alpine Cloud User
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: wheel
    shell: /bin/bash
    ssh_authorized_keys:
      - ${PUB}
package_update: true
packages:
  - bash
  - curl
  - openssh
  - python3
  - tzdata
  - sudo
  - doas
runcmd:
  - mkdir -p /opt/nanovm/agents /opt/nanovm/platform /var/log/nanovm /var/run/nanovm
  - rc-update add sshd default
  - rc-service sshd start
EOF

if command -v mkisofs >/dev/null 2>&1; then
  MKISO=mkisofs
elif command -v genisoimage >/dev/null 2>&1; then
  MKISO=genisoimage
else
  echo "Need mkisofs (brew install cdrtools)" >&2
  exit 1
fi

# NoCloud volume label must be CIDATA (case-sensitive on some guests).
"$MKISO" -output "$SEED" -volid CIDATA -joliet -rock \
  "${CLOUD_DIR}/user-data" "${CLOUD_DIR}/meta-data"
echo "Cloud-init seed: $SEED (${INSTANCE_ID})"
