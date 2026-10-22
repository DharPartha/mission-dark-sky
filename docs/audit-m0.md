# Milestone 0 Audit (2026-10-22)

Inventory of the repository before The Dark Sky work began, based only on files inspected.

## What was there
The repo held **Mission Dark Sky: Smart Town**, a Roblox simulation of one adaptive parking-lot
lighting zone (phases 1–6 of its own plan): sensors, an adaptive brightness engine, impact
estimates, eight scenarios, and a control panel (~1,700 lines of Luau, 14 spec documents).

| Item | Status | Decision |
|---|---|---|
| Rojo project + Git repo | Working | Kept; project file remapped to `DarkSky` folders |
| Runtime world builder pattern (build parts in script, hold character spawn) | Working | Reused the approach in `WorldBuilder` |
| Adaptive parking-lot engine, sensors, scenarios, impact | Working, but a different game | Retired (owner decision: replace the sim). Still in git history |
| Smart Town specs, architecture diagram, physical prototype doc | Working docs for the old game | Retired with the sim |
| `roblox/*.rbxl` place files | Binary, old game | Left untouched |
| Story, bosses, Lux Lens, Darkness Meter, Moon tips, bubbles, bikes | Missing | M1 builds the Leo slice; rest is M2–M3 |
| Art, audio, animations, rigged boss meshes | Missing | Placeholder parts; owner assets needed |

## Toolchain
| Tool | Found |
|---|---|
| Roblox Studio | Installed |
| Rojo | 7.7.1 |
| Luau CLI (`luau`, `luau-analyze`, `luau-compile`) | Installed |
| Selene / StyLua / luau-lsp | Not installed (no lint/format CI yet) |

## Owner decisions recorded
1. The Dark Sky replaces the Smart Town simulation in this repo.
2. In the slice, Aadi, Aditya, and Adrika are NPC companions; players use their own avatars. No unique abilities yet.
3. The home neighborhood is named **Byers Station** (replaces the spec's "Maple Hollow").

## Owner assets needed (later milestones)
- Original or licensed constellation creature models/meshes (Leo first), Moon character art.
- Bicycle model and headlamp.
- Ambient audio, Leo motif, constellation lock chord (AudioConfig is not built yet).
- Reviewed real-world fact cards with sources for the Star Journal.
- Approval of all dialogue and Moon tips before release.
