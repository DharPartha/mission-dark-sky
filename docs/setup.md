# Setup, Build, Test, Publish

## Tools
| Tool | Version | Why |
|---|---|---|
| Roblox Studio | current | Build, playtest, publish |
| Rojo | 7.7.1 (pinned in `rokit.toml`) | Syncs `src/` into Studio and builds the place file |
| Luau CLI (`luau`, `luau-compile`) | any recent release | Command-line self tests and compile check |
| Python 3 | 3.9+ | Runs the self-test bundler (`scripts/run_self_tests.py`) |
| Node.js | 20+ | Companion website tests (`node --test site/tests/`) |
With [Rokit](https://github.com/rojo-rbx/rokit) installed, `rokit install` gets the pinned Rojo.

## Clone and build
```bash
git clone https://github.com/aiklox-in/mission-dark-sky.git
cd mission-dark-sky
rojo build -o roblox/the-dark-sky.rbxl
```
Open `roblox/the-dark-sky.rbxl` in Studio. For live editing, run `rojo serve` and click **Connect**
in the Rojo plugin. The world is built by scripts at startup; the place file needs no hand-made parts.
`default.project.json` sets `Workspace.StreamingEnabled = true` and `Lighting.Technology = Future`.

## Command-line checks (no Studio needed)
```bash
python3 scripts/run_self_tests.py --emit-sample site/tests/fixtures/sample-report.txt
node --test site/tests/
```
The same checks run on GitHub in `.github/workflows/checks.yml`.

## Saving progress (DataStore) safely
Unpublished files (`PlaceId 0`) use memory-only saves and show "Test file: progress is not saved".
To test real saves without touching players' data:
1. **File → Publish to Roblox As → new experience**, e.g. "The Dark Sky (DEV)", kept **private**.
2. **Game Settings → Security → Enable Studio Access to API Services: ON** (dev experience only).
3. In `src/server/ServerConfig/DevConfig.luau` add the dev place to `DevPlaceIds` and your Roblox
   user id to `DevUserIds`. Saves then use the `DarkSkyProfiles` store, scope `dev`.
4. The public experience is any place not in `DevPlaceIds`: it counts as **production**, uses scope
   `prod`, and test tools are always off there. Never add a production PlaceId to `DevPlaceIds`.

## Developer test tools
Available only in a local file or the dev experience, and only to `DevUserIds` there. Settings →
type `RESET` in the box → **Reset world**, **Reset MY save**, or **Jump to:** a mission. A red
"TEST MODE" bar shows while they are available. Every request is re-checked on the server.

## Companion website
See `docs/companion-site.md`: enable GitHub Pages (Source: GitHub Actions), merge to `main`, then set
`ExperienceConfig.CompanionSiteUrl` to the published https URL.

## Publishing the real experience (owner only)
Only after owner approval of content, privacy, assets, and title (spec §14, §16). Publish to a
separate production experience; keep `RunSelfTestsOnStart` on (they are fast) and `EnableTestReset`
on or off as you prefer (it never works in production either way).

## Where things live
| Path | What |
|---|---|
| `src/shared/Config` | All editable content and tuning (see `docs/admin-config-guide.md`) |
| `src/shared/Shared` | Pure, tested logic (scoring, rules, saves, report) |
| `src/server` | Services, world builders, bosses, persistence, tests |
| `src/client` | UI and input controllers |
| `site/` | Companion website |
| `docs/` | Architecture, plan, stages, playthrough, acceptance, delivery report |
