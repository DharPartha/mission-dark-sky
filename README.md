# The Dark Sky

*A shared world. A shared responsibility.*

A cooperative Roblox adventure about responsible lighting. Three friends (Aadi, Aditya, and Adrika)
ride into the Glarelands to restore the corrupted constellations, guided by a friendly Moon who is
not as friendly as she seems. Core rule: **Don't eliminate light. Make every light count.**

The build contract is [`docs/specs/The_Dark_Sky_Complete_Claude_Build_Spec.txt`](docs/specs/The_Dark_Sky_Complete_Claude_Build_Spec.txt)
(it replaces the earlier PDF where they differ).

## Status: full game in progress — Stage B (foundations) built, awaiting Studio test

Plan: [`docs/plan/full-game-plan.md`](docs/plan/full-game-plan.md). Stage test steps: [`docs/stages/`](docs/stages/).
Stage B added data-driven missions, personal DataStore saves with session locks, rate-limited
remotes, developer-only test tools, anonymous analytics, the Star Journal, and graphics tiers.
The table below describes the Leo slice those systems currently run.

| Feature | State |
|---|---|
| Lantern Lane test area (street, 3 houses, crosswalk, sign) | Implemented, placeholder parts |
| 3 fixtures: corner streetlight, garage floodlight, safety-critical crosswalk light | Implemented |
| Inspect prompt → fixture menu with QUESTION / SHIELD / AIM / DIM / TIME / WARM + Undo | Implemented |
| Server validation (types, distance, cooldown, phase, safety rules) | Implemented |
| Lux Lens overlay (readings + glare zones) and before/after panel | Implemented |
| Darkness Meter (0–100, number + stars + ticks) driving stars, haze, tint, fireflies | Implemented |
| Leo encounter: wake → roar telegraph → temporary Glare → calmed constellation | Implemented |
| One Moon tip with team "Doubt it!" vote and Doubt Token | Implemented |
| Friends as NPC companions with phase-based hints | Implemented |
| Comic bubbles (4 styles, typewriter, tap, auto-advance, pause on telegraph) | Implemented |
| Config validator + 29 pure-logic self tests | Implemented, passing in CLI |
| Reduced motion, large text, high contrast | Implemented |
| Saves, Star Journal, graphics tiers, rate limits, dev tools | Implemented (Stage B), not yet Studio-tested |
| Full town, bikes, other realms, finale, report, website | Planned (Stages C–H) |

The Leo slice was started in Studio (config check and self tests passed there); the full
playthrough and all Stage B features are not yet Studio-verified. Test steps:
[`docs/stages/stage-b-foundations.md`](docs/stages/stage-b-foundations.md).

## Setup

Tools: Roblox Studio, [Rojo](https://rojo.space) 7.x (tested with 7.7.1), Python 3 and
[Luau](https://github.com/luau-lang/luau/releases) for the command-line self tests.

```bash
rojo build -o roblox/the-dark-sky.rbxl
```

Open `roblox/the-dark-sky.rbxl` in Studio, then for live editing run `rojo serve` and click
**Connect** in the Rojo plugin. Press **Play**. The world is built by script at startup, so the
place file needs no hand-made parts.

Command-line checks (no Studio needed):

```bash
python3 scripts/run_self_tests.py
```

## Docs
- [Milestone 1 plan and Studio test steps](docs/milestones/m1-leo-slice.md)
- [Milestone 0 audit](docs/audit-m0.md)
- [Architecture](docs/architecture.md)
- [Admin configuration guide](docs/admin-config-guide.md) (change text, tips, tuning without code)
- [Asset manifest](assets/manifest.csv)

All readings and scores are game estimates for teaching, not real measurements or standards.
