#!/usr/bin/env bash
# Load or interactively collect CURSOR_API_KEY (Composer / Cursor SDK).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${NANOVM_ENV_FILE:-${ROOT}/.env}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

if [[ -n "${CURSOR_API_KEY:-}" ]]; then
  export CURSOR_API_KEY
  return 0 2>/dev/null || exit 0
fi

if [[ ! -t 0 ]]; then
  echo "CURSOR_API_KEY is not set (set in ${ENV_FILE} or run from a terminal)" >&2
  return 1 2>/dev/null || exit 1
fi

echo ""
echo "Cursor API key required for Composer (model: ${CURSOR_MODEL:-composer-2.5})."
echo "Create one: https://cursor.com/dashboard/integrations"
read -rsp "CURSOR_API_KEY: " CURSOR_API_KEY
echo ""
if [[ -z "${CURSOR_API_KEY}" ]]; then
  echo "empty key; aborting" >&2
  return 1 2>/dev/null || exit 1
fi
export CURSOR_API_KEY
export CURSOR_MODEL="${CURSOR_MODEL:-composer-2.5}"

python3 - "$ENV_FILE" <<'PY'
import os
import sys

path = sys.argv[1]
pairs = (
    ("CURSOR_API_KEY", os.environ.get("CURSOR_API_KEY", "")),
    ("CURSOR_MODEL", os.environ.get("CURSOR_MODEL", "composer-2.5")),
)
lines: list[str] = []
if os.path.isfile(path):
    with open(path, encoding="utf-8") as f:
        for line in f:
            if line.split("=", 1)[0] in {p[0] for p in pairs}:
                continue
            lines.append(line.rstrip("\n"))
for key, val in pairs:
    lines.append(f"{key}={val}")
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
try:
    os.chmod(path, 0o600)
except OSError:
    pass
PY

return 0 2>/dev/null || true
