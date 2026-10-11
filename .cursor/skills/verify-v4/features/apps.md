# Apps catalog

Apps is the catalog page at `/apps`. A user opens it from the home nav, sees a search field for apps, and waits for the client to populate `#appContainer` from local data and scripts.

## Sub-features

- `apps-load` serves the Apps page shell with brand and search field.
- `apps-search-ui` exposes `#searchApps` for filtering.
- `apps-container` exposes `#appContainer` where results render after client JS runs.

## How to get to it (user POV)

- Click **Apps** on the home nav.
- Open `/apps` directly.
- From Games or Settings, click **Apps** in the shared nav.

## Driving it with verify-v4

Preconditions:

- Doctor passes for the verification instance.

- **Load page.** `curl -sS -o evidence/apps/page.html -w '%{http_code}' "$BASE_URL/apps"` → `200`.
- **Brand and search.** Body contains `Doge Unblocker`, `id="searchApps"`, and `id="appContainer"`.
- **Script.** `GET $BASE_URL/assets/js/apps.js?v=2.2` (or the version query the HTML references) returns 200.
- **Proof.** Save the HTML and a one-line `proof.txt` noting status and the three markers. Populated app tiles need a browser; if you only curl, say `shell-only` in the proof and do not claim tile contents.

## Gotchas

- The HTML shows `Loading apps...` until client JS runs. Curl will often still show that placeholder; that is expected for HTTP-only proof.
- Route is `/apps` (Express), not `/apps.html`.
