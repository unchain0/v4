# Home proxy bar

Home is the landing page at `/`. A user sees the Doge Unblocker chrome, types a URL or search query into the browse field, and reaches Settings, Games, Apps, and Site Info from the nav and footer.

## Sub-features

- `home-load` serves the branded landing HTML with the proxy form.
- `home-nav` exposes Settings, Games, and Apps controls that route to their pages.
- `home-assets` loads CSS/JS the page references.
- `home-proxy-mounts` exposes baremux (and UV) static mounts the client stack needs.
- `home-404` shows the branded 404 page for unknown paths.

## How to get to it (user POV)

- Open the site root `/` after launch.
- Click **Settings**, **Games**, or **Apps** in the top nav.
- Follow **Site Info** in the bottom-right content.
- Type into the field placeholder `Type URL or search query` and submit the form (browser; client JS handles navigation into the proxy loader).

## Driving it with verify-v4

Preconditions:

- `bash .cursor/skills/verify-v4/scripts/launch.sh` printed `ready`.
- `bash .cursor/skills/verify-v4/scripts/doctor.sh` printed `doctor: ok`.

- **Load home.** Fetch the root. Run `bash .cursor/skills/verify-v4/scripts/drive-home.sh`. Expect `01-home.html` to contain `Doge Unblocker`, `name="url"`, and `browse-input`, with HTTP 200 headers.
- **Nav targets.** The same script fetches `/apps`, `/gms`, `/settings.html`, and `/info`. Each body contains `Doge Unblocker` and status 200.
- **Assets.** The same script asserts `/assets/css/app.css?v=3` and `/assets/js/main.js?v=3` return 200.
- **Proxy client mount.** The same script asserts `/baremux/index.js` returns 200.
- **Unknown path.** The same script asserts `/__verify_missing_path__` returns 404 and branded HTML.
- **Proof.** Artifacts land in `.cursor/skills/verify-v4/evidence/home-<timestamp>/` including `proof.txt` with `result=pass`.

Manual one-off (same checks without the helper):

```bash
source /tmp/v4-verify/state.env
curl -sS -D /tmp/v4-home.hdr -o /tmp/v4-home.html "$BASE_URL/"
grep -q 'Doge Unblocker' /tmp/v4-home.html
grep -q 'name="url"' /tmp/v4-home.html
```

Do not leave `/tmp/v4-home.*` as the durable proof location; copy into `evidence/` or use `drive-home.sh`.

## Gotchas

- Default `npm start` binds `8001`. Verification uses `18001` via `PORT`. Driving `8001` without doctor state is invalid for this skill.
- Submitting the URL form needs a browser and client JS (`/assets/js/index.js`, baremux, UV). A curl of `/` alone does not open a proxied destination; that is a separate live-proxy proof.
- `/worker.js` is fetched from a remote host by the server. A failure there is an external dependency, not a home HTML failure.
- Cleanup deletes `/tmp/v4-verify` only. If you wrote proof only under `/tmp`, it vanishes; keep proof under `evidence/`.
