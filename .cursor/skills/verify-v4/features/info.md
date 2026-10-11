# Site info

Site info is the informational page at `/info`. A user reaches it from the home footer link **Site Info**.

## Sub-features

- `info-load` serves the info page with brand chrome.
- `info-related` covers adjacent loader routes the app registers (`/mastery`, `/lessons`, `/mycourses`) when a change touches those mappings.

## How to get to it (user POV)

- Click **Site Info** on the home page.
- Open `/info` directly.

## Driving it with verify-v4

Preconditions:

- Doctor passes for the verification instance.

- **Load page.** `curl -sS -w '%{http_code}' -o evidence/info/page.html "$BASE_URL/info"` → `200`.
- **Brand.** Body contains `Doge Unblocker`.
- **Related routes (optional).** When proving route table changes, also `GET` `/mastery`, `/lessons`, `/mycourses` and expect 200 with their static files (`loader.html`, `agloader.html`, `/loading.html`).
- **Proof.** Save HTML and statuses under `evidence/info-<timestamp>/`.

## Gotchas

- `/student` redirects to `/portal`. `/portal` is not a defined route in `index.js` and will 404 with the branded page; do not treat that redirect target as a successful page unless the app gains one.
- `/info` is an Express route to `static/info.html`, not a bare static path requirement.
