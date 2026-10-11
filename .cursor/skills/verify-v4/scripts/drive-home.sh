#!/usr/bin/env bash
# Drive the home / proxy-bar feature once and write proof under evidence/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"

bash "${SCRIPT_DIR}/doctor.sh"

verify_load_state

RUN_ID="${VERIFY_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
OUT="${VERIFY_EVIDENCE}/home-${RUN_ID}"
mkdir -p "${OUT}"

fail() {
  echo "drive-home: FAIL: $*" >&2
  exit 1
}

# 1. Fetch home (the real user entry point).
curl -sS -D "${OUT}/01-home.headers" -o "${OUT}/01-home.html" "${BASE_URL}/" \
  || fail "GET / failed"
grep -qi '^HTTP/.* 200' "${OUT}/01-home.headers" || fail "home status not 200"
grep -q "Doge Unblocker" "${OUT}/01-home.html" || fail "home missing brand text"
grep -q 'name="url"' "${OUT}/01-home.html" || fail "home missing url input"
grep -q 'class="browse-input' "${OUT}/01-home.html" || fail "home missing browse-input"
grep -q "Settings" "${OUT}/01-home.html" || fail "home missing Settings nav"
grep -q "Games" "${OUT}/01-home.html" || fail "home missing Games nav"
grep -q "Apps" "${OUT}/01-home.html" || fail "home missing Apps nav"

# 2. Follow nav targets the home page offers (user can reach each from home).
for path_label in "apps:/apps" "gms:/gms" "settings:/settings.html" "info:/info"; do
  name="${path_label%%:*}"
  path="${path_label#*:}"
  code="$(curl -sS -o "${OUT}/02-${name}.html" -w '%{http_code}' "${BASE_URL}${path}")"
  [[ "${code}" == "200" ]] || fail "GET ${path} returned ${code}"
  grep -q "Doge Unblocker" "${OUT}/02-${name}.html" || fail "${path} missing brand text"
done

# 3. Static assets the home page references must resolve (side effect of serving UI).
css_code="$(curl -sS -o /dev/null -w '%{http_code}' "${BASE_URL}/assets/css/app.css?v=3")"
[[ "${css_code}" == "200" ]] || fail "GET /assets/css/app.css returned ${css_code}"
js_code="$(curl -sS -o /dev/null -w '%{http_code}' "${BASE_URL}/assets/js/main.js?v=3")"
[[ "${js_code}" == "200" ]] || fail "GET /assets/js/main.js returned ${js_code}"

# 4. UV and baremux mounts the proxy stack needs on the home path.
baremux_code="$(curl -sS -o /dev/null -w '%{http_code}' "${BASE_URL}/baremux/index.js")"
[[ "${baremux_code}" == "200" ]] || fail "GET /baremux/index.js returned ${baremux_code}"

# 5. Unknown path still serves the app 404 page (user-visible).
notfound_code="$(curl -sS -o "${OUT}/03-404.html" -w '%{http_code}' "${BASE_URL}/__verify_missing_path__")"
[[ "${notfound_code}" == "404" ]] || fail "missing path returned ${notfound_code}, expected 404"
grep -q "Doge Unblocker" "${OUT}/03-404.html" || fail "404 page missing brand text"

# Proof summary (no secrets; this app has none for local verify).
{
  echo "feature=home"
  echo "run_id=${RUN_ID}"
  echo "base_url=${BASE_URL}"
  echo "pid=${PID}"
  echo "home_has_url_input=yes"
  echo "home_has_nav=Settings,Games,Apps"
  echo "apps_status=200"
  echo "gms_status=200"
  echo "settings_status=200"
  echo "info_status=200"
  echo "app_css_status=${css_code}"
  echo "main_js_status=${js_code}"
  echo "baremux_status=${baremux_code}"
  echo "missing_path_status=${notfound_code}"
  echo "result=pass"
} >"${OUT}/proof.txt"

echo "drive-home: ok evidence=${OUT}"
