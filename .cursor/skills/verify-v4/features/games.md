# Games catalog

Games is the catalog page at `/gms`. A user opens it from the home nav, searches games, and gets tiles filled by client JS.

## Sub-features

- `games-load` serves the Games page shell with brand and search field.
- `games-search-ui` exposes `#searchApps` (shared id with Apps) for filtering.
- `games-data` depends on `static/data/*-list.json` and game scripts once the browser runs.

## How to get to it (user POV)

- Click **Games** on the home nav.
- Open `/gms` directly.

## Driving it with verify-v4

Preconditions:

- Doctor passes for the verification instance.

- **Load page.** `curl -sS -w '%{http_code}' -o evidence/games/page.html "$BASE_URL/gms"` → `200`.
- **Brand and search.** Body contains `Doge Unblocker` and `id="searchApps"`.
- **Data files.** `GET $BASE_URL/static/data/...` is wrong; data is under `/data/` via `express.static('static')`. Prefer `GET $BASE_URL/data/g-list.json` (or the file the page's JS requests) and expect 200 JSON.
- **Proof.** Save HTML plus data response status. Tile contents need a browser.

## Gotchas

- Path is `/gms`, not `/games`.
- Like Apps, curl sees the pre-JS shell. Do not fail the shell proof because tiles are empty in the static HTML.
