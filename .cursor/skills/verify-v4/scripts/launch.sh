#!/usr/bin/env bash
# Start one isolated Doge Unblocker (v4) instance for verification.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if [[ -f "${VERIFY_STATE}" ]]; then
  # shellcheck disable=SC1090
  source "${VERIFY_STATE}"
  if verify_pid_alive "${PID:-}"; then
    echo "Verification server already running at ${BASE_URL} pid=${PID}."
    echo "Refusing to start a second copy. Run scripts/doctor.sh, or scripts/cleanup.sh first."
    exit 0
  fi
fi

listeners="$(verify_listener_pids "${VERIFY_PORT}")"
if [[ -n "${listeners}" ]]; then
  echo "Port ${VERIFY_PORT} is already taken by pid(s): ${listeners//$'\n'/, }." >&2
  echo "That process was not started by this skill. Refusing to kill it or share it." >&2
  exit 1
fi

if [[ ! -d "${VERIFY_REPO_ROOT}/node_modules" ]]; then
  (cd "${VERIFY_REPO_ROOT}" && npm install)
fi

if [[ ! -f "${VERIFY_REPO_ROOT}/index.js" ]]; then
  echo "Missing index.js at repo root ${VERIFY_REPO_ROOT}." >&2
  exit 1
fi

rm -rf "${VERIFY_SCRATCH}"
mkdir -p "${VERIFY_SCRATCH}" "${VERIFY_EVIDENCE}"

LOG_PATH="${VERIFY_SCRATCH}/server.log"
BASE_URL="http://${VERIFY_HOST}:${VERIFY_PORT}"

# Bind only to the verification host/port. PORT is the tiny harness hook in index.js.
nohup env \
  PORT="${VERIFY_PORT}" \
  HOST="${VERIFY_HOST}" \
  node "${VERIFY_REPO_ROOT}/index.js" \
  >"${LOG_PATH}" 2>&1 </dev/null &
PID="$!"

cat >"${VERIFY_STATE}" <<EOF
PID=${PID}
PORT=${VERIFY_PORT}
HOST=${VERIFY_HOST}
BASE_URL=${BASE_URL}
SCRATCH=${VERIFY_SCRATCH}
LOG_PATH=${LOG_PATH}
REPO_ROOT=${VERIFY_REPO_ROOT}
EOF

ready=0
for _ in $(seq 1 60); do
  if curl -sf "${BASE_URL}/" >/dev/null 2>&1; then
    ready=1
    break
  fi
  if ! verify_pid_alive "${PID}"; then
    echo "Server exited before it was ready. Log follows." >&2
    cat "${LOG_PATH}" >&2 || true
    exit 1
  fi
  sleep 0.25
done

if [[ "${ready}" != "1" ]]; then
  echo "Server did not answer ${BASE_URL}/ within 15s. Log follows." >&2
  cat "${LOG_PATH}" >&2 || true
  exit 1
fi

echo "ready ${BASE_URL} pid=${PID}"
