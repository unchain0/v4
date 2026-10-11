#!/usr/bin/env bash
# Stop the verification server this skill started and delete its scratch state.
# Evidence under .cursor/skills/verify-v4/evidence is left in place.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

if [[ -f "${VERIFY_STATE}" ]]; then
  # shellcheck disable=SC1090
  source "${VERIFY_STATE}"
  if [[ -n "${PID:-}" ]] && verify_pid_alive "${PID}"; then
    # Only signal our recorded pid (and its descendants). Never kill by name.
    if verify_cmdline_has "${PID}" "index.js"; then
      mapfile -t descendants < <(verify_descendant_pids "${PID}")
      for child in "${descendants[@]}"; do
        kill -TERM "${child}" 2>/dev/null || true
      done
      kill -TERM "${PID}" 2>/dev/null || true
      for _ in $(seq 1 40); do
        verify_pid_alive "${PID}" || break
        sleep 0.25
      done
      if verify_pid_alive "${PID}"; then
        for child in "${descendants[@]}"; do
          kill -KILL "${child}" 2>/dev/null || true
        done
        kill -KILL "${PID}" 2>/dev/null || true
      fi
    else
      echo "cleanup: pid ${PID} no longer looks like index.js; leaving it alone" >&2
    fi
  fi
fi

if [[ -n "${SCRATCH:-}" && "${SCRATCH}" != "/" && -d "${SCRATCH}" ]]; then
  rm -rf "${SCRATCH}"
elif [[ -d "${VERIFY_SCRATCH}" ]]; then
  rm -rf "${VERIFY_SCRATCH}"
fi

echo "cleanup: stopped verification server and removed scratch state"
echo "cleanup: evidence kept at ${VERIFY_EVIDENCE}"
