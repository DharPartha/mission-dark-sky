# The Dark Sky

*A shared world. A shared responsibility.*

A cooperative Roblox adventure about responsible outdoor lighting. Three friends — Aadi, Aditya, and
Adrika — notice the stars missing over Byers Station (a fictional town), ride through a Rift into the
Glarelands, restore four corrupted constellations, and uncover the Moon's secret.
Core rule: **Don't eliminate light. Make every light count.**

Build contract: [`docs/specs/The_Dark_Sky_Complete_Claude_Build_Spec.txt`](docs/specs/The_Dark_Sky_Complete_Claude_Build_Spec.txt).

## Status: release candidate 0.9.0-rc1 — implemented end to end, not yet playtested in Studio
See the [delivery report](docs/delivery-report.md) for what is verified and what is not, and the
[acceptance checklist](docs/acceptance-checklist.md) for each spec criterion.

| Part | What's in it |
|---|---|
| Act I | Starlight Hub sleepover, pre-check, telescope, Lux Lens + Star Journal, Lantern Lane tutorial, bikes, covered-bridge Rift |
| Act II | Leo (glare), Orion (sports lights, timers), Scorpius (spill, color), Cetus (pond glare) — puzzles, guardians, Moon tips, town echoes |
| Act III | Moon clues, reveal, five-phase finale (QUESTION, SHIELD & AIM, DIM, TIME, CHOOSE WISELY), ending, achievement |
| After | Post-check, Night Sky Pledge + Star Card, community report → companion website PDF |
| Systems | DataStore saves with locks/recovery, co-op + solo fairness, hints, accessibility, gamepad/mobile, dev tools, anonymous evaluation events |

## Quick start
```bash
rojo build -o roblox/the-dark-sky.rbxl
python3 scripts/run_self_tests.py
node --test site/tests/
```
Open the place file in Studio and press **Play**. Full instructions: [`docs/setup.md`](docs/setup.md).

## Docs
- [Setup, saves, publishing](docs/setup.md) · [Architecture](docs/architecture.md) · [Admin config guide](docs/admin-config-guide.md)
- [Full playthrough script](docs/playthrough.md) · [Known issues](docs/known-issues.md) · [Evaluation](docs/evaluation.md)
- [Companion website](docs/companion-site.md) · [Stage notes](docs/stages/) · [Plan](docs/plan/full-game-plan.md)
- [Asset manifest](assets/manifest.csv) · [Tests](tests/README.md)

All readings and scores in the game are simulated estimates for learning, not real measurements.
