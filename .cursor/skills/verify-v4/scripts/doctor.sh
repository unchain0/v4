#!/usr/bin/env bash
# Read-only check: is the verification Doge Unblocker instance worth driving?
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
verify_load_state

fail() {
  echo "doctor: not ready: $*" >&2
  exit 1
}

verify_pid_alive "${PID}" || fail "pid ${PID} is not running"
[[ -d "/proc/${PID}" ]] || fail "pid ${PID} has no /proc entry"
verify_cmdline_has "${PID}" "index.js" || fail "pid ${PID} cmdline is not the v4 index.js server"

listeners="$(verify_listener_pids "${PORT}")"
[[ -n "${listeners}" ]] || fail "nothing is listening on port ${PORT}"

owned=0
while IFS= read -r listener; do
  [[ -z "${listener}" ]] && continue
  if [[ "${listener}" == "${PID}" ]] || verify_is_ancestor "${PID}" "${listener}"; then
    owned=1
    break
  fi
done <<<"${listeners}"
[[ "${owned}" == "1" ]] || fail "port ${PORT} is owned by pid(s) ${listeners//$'\n'/, }, not ${PID}"

html="$(curl -sf "${BASE_URL}/")" || fail "GET / failed"
grep -q "Doge Unblocker" <<<"${html}" || fail "home HTML is missing 'Doge Unblocker'"
grep -q 'name="url"' <<<"${html}" || fail "home HTML is missing the proxy URL input"
grep -q 'browse-input' <<<"${html}" || fail "home HTML is missing the browse-input class"

code_apps="$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}/apps")"
[[ "${code_apps}" == "200" ]] || fail "GET /apps returned ${code_apps}"

code_uv="$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}/uv/")"
# UV static may 404 on bare /uv/ depending on express.static; accept 200 or 301/302/404 only if package path mounted.
# Prefer a known package asset path from @titaniumnetwork-dev/ultraviolet.
if [[ "${code_uv}" != "200" && "${code_uv}" != "301" && "${code_uv}" != "302" && "${code_uv}" != "403" && "${code_uv}" != "404" ]]; then
  fail "GET /uv/ returned unexpected ${code_uv}"
fi

echo "doctor: ok ${BASE_URL} pid=${PID}"
