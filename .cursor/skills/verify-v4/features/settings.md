# Settings

Settings is `/settings.html`. A user opens cloaking and preference controls (tab cloak, about:blank cloak, clickoff cloak, leave confirmation, and related options) from the home nav or the right-click context menu entry **View all Settings**.

## Sub-features

- `settings-load` serves the settings page with `#settingsContainer`.
- `settings-tab-cloak` exposes cloak option buttons (`driveCloak`, `docsCloak`, `googleCloak`, `classroomCloak`, `disableTabCloak`).
- `settings-about-blank` exposes **Open Blanker** and enable/disable about:blank controls.
- `settings-clickoff` exposes enable/disable clickoff cloak buttons `#ecc` / `#dcc`.

## How to get to it (user POV)

- Click **Settings** on the home nav.
- Open `/settings.html` directly.
- Right-click → **View all Settings** (browser).

## Driving it with verify-v4

Preconditions:

- Doctor passes for the verification instance.

- **Load page.** `curl -sS -w '%{http_code}' -o evidence/settings/page.html "$BASE_URL/settings.html"` → `200`.
- **Container.** Body contains `id="settingsContainer"`, text `Tab Cloaking`, and `About:Blank Cloak`.
- **Styles.** `GET $BASE_URL/assets/css/settings.css?v=3` returns 200.
- **Proof.** Save HTML and status. Toggling cloaks mutates `document` title/local state in the browser only; HTTP proof stops at the controls being present. Browser proof should show a title change after a cloak click and note it is client-side.

## Gotchas

- File is `settings.html` at the site root (static), not an Express named route.
- Cloak actions need a real browser document; curl cannot assert title changes.
