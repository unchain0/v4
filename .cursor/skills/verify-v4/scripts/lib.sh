#!/usr/bin/env bash
# Shared paths for the Doge Unblocker (v4 / surfdoge) verification instance.
# Source this file; do not execute it.

set -euo pipefail

VERIFY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_SKILL_DIR="$(cd "${VERIFY_LIB_DIR}/.." && pwd)"
VERIFY_REPO_ROOT="$(cd "${VERIFY_SKILL_DIR}/../../.." && pwd)"
VERIFY_SCRATCH="${VERIFY_SCRATCH:-/tmp/v4-verify}"
VERIFY_STATE="${VERIFY_SCRATCH}/state.env"
# Default 18001 so a user instance on the app default 8001 is left alone.
VERIFY_PORT="${VERIFY_PORT:-18001}"
VERIFY_EVIDENCE="${VERIFY_SKILL_DIR}/evidence"
VERIFY_HOST="${VERIFY_HOST:-127.0.0.1}"

verify_load_state() {
  if [[ ! -f "${VERIFY_STATE}" ]]; then
    echo "No verification state at ${VERIFY_STATE}. Run scripts/launch.sh first." >&2
    return 1
  fi
  # shellcheck disable=SC1090
  source "${VERIFY_STATE}"
}

# Prints listening pids for a TCP port, one per line. Empty if none.
verify_listener_pids() {
  local port="$1"
  python3 - "${port}" <<'PY'
import os
import pathlib
import sys

port = int(sys.argv[1])
hexport = f"{port:04X}"
inodes = set()
for name in ("/proc/net/tcp", "/proc/net/tcp6"):
    path = pathlib.Path(name)
    if not path.exists():
        continue
    for line in path.read_text().splitlines()[1:]:
        parts = line.split()
        local, state, inode = parts[1], parts[3], parts[9]
        if state == "0A" and local.rsplit(":", 1)[-1].upper() == hexport:
            inodes.add(inode)
pids = []
for proc in pathlib.Path("/proc").iterdir():
    if not proc.name.isdigit():
        continue
    fd_dir = proc / "fd"
    try:
        fds = list(fd_dir.iterdir())
    except OSError:
        continue
    for fd in fds:
        try:
            target = os.readlink(fd)
        except OSError:
            continue
        if target.startswith("socket:[") and target[8:-1] in inodes:
            pids.append(proc.name)
            break
print("\n".join(pids))
PY
}

verify_is_ancestor() {
  local ancestor="$1"
  local pid="$2"
  python3 - "${ancestor}" "${pid}" <<'PY'
import pathlib
import sys

ancestor = int(sys.argv[1])
pid = int(sys.argv[2])
seen = set()
while pid > 1 and pid not in seen:
    if pid == ancestor:
        sys.exit(0)
    seen.add(pid)
    try:
        text = pathlib.Path(f"/proc/{pid}/stat").read_text()
    except OSError:
        sys.exit(1)
    after = text.rsplit(")", 1)[1].split()
    pid = int(after[1])
sys.exit(1)
PY
}

verify_pid_alive() {
  local pid="$1"
  [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null
}

verify_descendant_pids() {
  local root="$1"
  python3 - "${root}" <<'PY'
import pathlib
import sys

root = int(sys.argv[1])
children = {}
for proc in pathlib.Path("/proc").iterdir():
    if not proc.name.isdigit():
        continue
    try:
        text = (proc / "stat").read_text()
    except OSError:
        continue
    ppid = int(text.rsplit(")", 1)[1].split()[1])
    children.setdefault(ppid, []).append(int(proc.name))

order = []
stack = [root]
while stack:
    pid = stack.pop()
    for child in children.get(pid, []):
        order.append(child)
        stack.append(child)
print("\n".join(str(pid) for pid in reversed(order)))
PY
}

verify_cmdline_has() {
  local pid="$1"
  local needle="$2"
  python3 - "${pid}" "${needle}" <<'PY'
import pathlib
import sys
pid, needle = sys.argv[1], sys.argv[2]
try:
    raw = pathlib.Path(f"/proc/{pid}/cmdline").read_bytes()
except OSError:
    sys.exit(1)
sys.exit(0 if needle.encode() in raw.replace(b"\x00", b" ") else 1)
PY
}
