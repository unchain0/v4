---
name: verify-v4
description: >-
  Launch and drive Doge Unblocker v4 (surfdoge) the way a user does — home proxy
  bar, Apps, Games, Settings, Info — over HTTP on an isolated port, then capture
  proof. Use when a change needs a real user-path check against the local Node
  server, a UI route regression, or a feature in the map needs evidence.
---

# Verify Doge Unblocker v4

The primary surface is the Express + Ultraviolet web UI in `static/`, served by `index.js` (`npm start`). A person opens the site in a browser, types a URL or search on the home bar, and reaches Apps, Games, Settings, and Info from the nav.

Secondary surfaces this skill does not fully drive by default:

- Live proxying of third-party sites through Ultraviolet / bare / wisp (`/seal/`, `/wisp/`, `/worker.js` remote fetch). Those need an outbound network path and a real destination; map them only when the change is in the proxy stack and you can name the destination.
- Deploy targets (`render.yaml`, `vercel.json`, `Dockerfile`). Prove local behavior first.

Two verification instances can run side by side only if each has its own `VERIFY_PORT`. The app default without `PORT` is `8001`. This skill defaults to `18001` so it does not attach to a user's ordinary `npm start`. Do not drive a process this skill did not start. Do not kill whatever already owns the port.

Local requirements: Node `>=16`, `npm >=7`, network only for `npm install` (and optional live-proxy proofs). No app secrets; do not invent password or token literals in this skill.

## Launch

From the repository root:

```bash
bash .cursor/skills/verify-v4/scripts/launch.sh
```

The helper:

1. Refuses if a prior verification pid in `/tmp/v4-verify/state.env` is still alive.
2. Refuses if `VERIFY_PORT` (default `18001`) is already taken by any process.
3. Runs `npm install` when `node_modules` is missing.
4. Starts `node index.js` with `PORT=${VERIFY_PORT}` (tiny harness hook in `index.js`; production still defaults to `8001` when `PORT` is unset).
5. Waits until `GET http://127.0.0.1:${VERIFY_PORT}/` returns HTTP 200.

Ready means the home page responds. The server log line includes `Welcome to Doge V4` and prints the bound port. State is written to `/tmp/v4-verify/state.env` (`PID`, `PORT`, `BASE_URL`, `LOG_PATH`). Logs live at `/tmp/v4-verify/server.log`.

Override the port when needed:

```bash
VERIFY_PORT=18011 bash .cursor/skills/verify-v4/scripts/launch.sh
```

## Doctor

Run this before driving, and whenever anything looks off. It only reads:

```bash
bash .cursor/skills/verify-v4/scripts/doctor.sh
```

It passes only when all of these are true:

- The pid in `/tmp/v4-verify/state.env` is alive and its cmdline still contains `index.js`.
- That pid (or a descendant) owns the listening socket for `PORT`.
- `GET $BASE_URL/` returns HTML containing `Doge Unblocker`, `name="url"`, and `browse-input`.
- `GET $BASE_URL/apps` returns 200.

A passing doctor prints `doctor: ok http://127.0.0.1:<port> pid=<pid>`. Anything else prints `doctor: not ready:` and a reason. Do not drive a failing instance, and do not fall back to port `8001` to compensate.

## Drive

There is no Playwright suite in this repo. Drive the user-visible HTTP surface with the helpers (curl against the instance origin). Load state only through the scripts; do not attach to an arbitrary local server.

Home / proxy bar (the feature proved with this skill once at creation):

```bash
bash .cursor/skills/verify-v4/scripts/drive-home.sh
```

The script runs doctor, then:

1. `GET /` and asserts brand text, the `url` input (`browse-input`), and nav labels Settings / Games / Apps.
2. `GET /apps`, `/gms`, `/settings.html`, `/info` each return 200 with brand text (paths the home nav reaches).
3. `GET /assets/css/app.css?v=3` and `GET /assets/js/main.js?v=3` return 200 (assets the home page loads).
4. `GET /baremux/index.js` returns 200 (proxy client stack mount).
5. `GET /__verify_missing_path__` returns 404 with the branded 404 page.

Stable handles and routes:

| Surface | Handle / path |
| --- | --- |
| Home brand | text `Doge Unblocker` in `/` |
| Proxy URL field | `input[name="url"].browse-input` on `/` |
| Settings nav | button calling `send('/settings.html')` → `/settings.html` |
| Games nav | `send('/gms')` → `/gms` |
| Apps nav | `send('/apps')` → `/apps` |
| Site info | link `/info` |
| Settings root | `#settingsContainer` on `/settings.html` |
| Apps search | `#searchApps` on `/apps` |
| Games search | `#searchApps` on `/gms` |
| UV static | `/uv/` (package mount) |
| Bare server | `/seal/` (only when proving live bare routing) |

Per-feature sequences are in `features/`. A proof of home does not cover live proxy destinations.

## Evidence

Write proof into `.cursor/skills/verify-v4/evidence/`. That directory is gitignored except `README.md` and `.gitignore`. Cleanup never removes it.

`drive-home.sh` writes `evidence/home-<UTC-timestamp>/`:

- `01-home.html` and `01-home.headers` for the landing page
- `02-apps.html`, `02-gms.html`, `02-settings.html`, `02-info.html` for nav targets
- `03-404.html` for the missing-path page
- `proof.txt` with status flags and `result=pass`

Standards:

- Exercise the real static routes and mounts the browser would hit. Do not open HTML files from disk and call that a server proof.
- Capture the action and the resulting bodies, not only a final status code.
- Side effects here are served files and mounts. Confirm CSS/JS/baremux bytes arrive with 200 alongside the HTML.
- Do not treat a live third-party fetch through the proxy as required for the home proof. When you do prove proxying, name the destination and keep response bodies free of credentials.
- Never hardcode secret-looking literals in scripts or proof. This app has no local auth; do not invent any.

## Cleanup

```bash
bash .cursor/skills/verify-v4/scripts/cleanup.sh
```

The helper reads the pid from `/tmp/v4-verify/state.env`, signals that pid and its descendants only when the cmdline still contains `index.js`, and deletes `/tmp/v4-verify`. It does not delete `.cursor/skills/verify-v4/evidence/`. It does not use `killall`/`pkill`, and it does not stop a server on port `8001` it did not start.

Run cleanup after a failed launch or drive too, so the next launch is not attached to a half-started process.

## Helpers

| Script | Invocation |
| --- | --- |
| `scripts/lib.sh` | Sourced by the shell helpers. Do not run it directly. |
| `scripts/launch.sh` | `bash .cursor/skills/verify-v4/scripts/launch.sh` |
| `scripts/doctor.sh` | `bash .cursor/skills/verify-v4/scripts/doctor.sh` |
| `scripts/cleanup.sh` | `bash .cursor/skills/verify-v4/scripts/cleanup.sh` |
| `scripts/drive-home.sh` | `bash .cursor/skills/verify-v4/scripts/drive-home.sh` |

All helpers are executable. They share state only through `/tmp/v4-verify/state.env`.
