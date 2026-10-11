# Doge Unblocker v4 verification map

This directory is the maintained source for verifying user-facing behavior of Doge Unblocker v4 (package name `surfdoge`). Read the index before driving the app, then use the matching feature file as the recipe.

## Baseline preconditions

- Launch with `bash .cursor/skills/verify-v4/scripts/launch.sh` so the instance binds `VERIFY_PORT` (default `18001`) and writes `/tmp/v4-verify/state.env`.
- Run `bash .cursor/skills/verify-v4/scripts/doctor.sh` and require `doctor: ok` with the expected `BASE_URL` and pid.
- Never drive an instance that was not started by this verification run. Do not attach to a user's `npm start` on port `8001`.
- Keep proof under `.cursor/skills/verify-v4/evidence/`. Cleanup must not remove it.

## Driving conventions

- Start every recipe from a doctor-passing baseline unless its preconditions say otherwise.
- Prefer path strings and stable DOM ids/classes from `static/` (`browse-input`, `#searchApps`, `#settingsContainer`) over coordinates.
- Treat every command as literal. Keep quoted paths and flags unchanged.
- HTTP proofs use `curl` against `$BASE_URL` from state. Browser proofs (optional) must target that same origin only.
- Restore nothing on disk after a run; the app is static-plus-proxy with no local user database. Still stop the instance you started.

## Proof and skip reporting

- Capture the request and the resulting body or status, not only a final screenshot.
- Mutation/side-effect proof for this app is served assets and mounts (CSS, JS, baremux, UV). Confirm those with HTTP status alongside page HTML.
- Live proxying of external sites is optional and network-dependent. Report an unreachable external destination with the attempted URL and the failure; do not mark home as failed because an external host is down.
- Record the feature id and entry point with every artifact directory name.
- Do not report a skipped entry point as verified through a different path.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the user-visible behavior. It then uses exactly four H2 sections in this order.

1. `Sub-features` lists short IDs with one line for each behavior.
2. `How to get to it (user POV)` lists every user entry point.
3. `Driving it with verify-v4` starts with `Preconditions:` and uses labeled bullets that pair each user action with an exact command and observable result.
4. `Gotchas` lists traps that can waste or invalidate a verification run.

Keep implementation details out of the map. Name only user paths, stable handles, required state, commands, and observable proof.

## Features

- [Home proxy bar](./home.md) covers the landing page, URL/search field, nav, and core static mounts.
- [Apps catalog](./apps.md) covers `/apps` and app search UI shell.
- [Games catalog](./games.md) covers `/gms` and games search UI shell.
- [Settings](./settings.md) covers `/settings.html` cloaking and preference controls.
- [Site info](./info.md) covers `/info` and related informational routes.
