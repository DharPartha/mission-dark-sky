# Delivery Report — The Dark Sky (release candidate 0.9.0-rc1)

Branch `full-game` (from `m1-leo-vertical-slice`), built in stages B–H after the approved plan
(`docs/plan/full-game-plan.md`) against `docs/specs/The_Dark_Sky_Complete_Claude_Build_Spec.txt`.

## Bottom line
The whole game is implemented end to end in code: opening, Byers Station, bikes, four realms with
guardians, the Moon reveal and five-phase finale, ending, achievement, pledge, post-check, community
report, companion website, saves, co-op handling, accessibility, and developer tools.
**It has not been playtested in Roblox Studio beyond the first server start**, so this is a release
candidate for testing, not a verified release. Run `docs/playthrough.md` next.

## What is verified, and how
| Evidence | Result |
|---|---|
| 44 Luau self tests (CLI and at every server start) | Pass: scoring, safety rules, all 6 zones' balance, finale phases solvable, saves (outage, corrupt, newer version, locks, migration v0→v3, recovery merge), rate limiter, pledge/quiz/settings validation, party rules, report format |
| Config validator | 0 errors, 0 warnings across all content files |
| Every Luau file compiles; Rojo build succeeds | Pass |
| Cross-checks (Stage H) | Every module call, UI text key, dialogue sequence, remote, and client-read attribute exists |
| 11 companion website tests | Pass, including parsing the game's own report output, no network, no HTML injection |
| Companion website in a browser | Rendered the game's sample report correctly; no console errors; fits 375 px phones |
| Studio | Milestone 1 server start only (config check + self tests passed). Nothing after that |

## Bugs found and fixed during Stage H review
1. The starting objective pointed at a text key removed in Stage C (would show "[objective_intro]").
2. Players joining after the ending would have seen the end card; now only finishers do.
3. Gamepad Journal shortcut used the Select button, which Roblox reserves for menu navigation; moved
   to D-pad down.
(Earlier stages also fixed: report preview contrast, re-entrant world rebuild on resume, quiz results
disappearing too early, UI start-up blocked by the shadow budget, and others noted in each stage doc.)

## Scope delivered (spec §13 stages)
| Stage | Delivered | Doc |
|---|---|---|
| A Audit + plan | Audit, approved plan | `docs/audit-m0.md`, `docs/plan/full-game-plan.md` |
| B Foundations | Data-driven missions, DataStore saves with locks/retries/migrations, rate-limited remotes, dev tools, analytics, Journal, quality tiers | `docs/stages/stage-b-foundations.md` |
| C Opening + town | Full town, Starlight Hub opening, pre-check, tutorial, bikes, hints, Rift, Glarelands | `docs/stages/stage-c-opening.md` |
| D Realms | Leo, Orion, Scorpius, Cetus; boss framework; town echoes; Moon clues | `docs/stages/stage-d-realms.md` |
| E Finale | Reveal, five phases, ending, achievement, pledge, Star Card, end card | `docs/stages/stage-e-finale.md` |
| F Learning + report | Post-check, evaluation events, report, companion site, Pages workflow | `docs/stages/stage-f-report.md` |
| G Polish | Party-size fairness, leave/late-join/respawn, save recovery, saved settings, controls, shadow budget | `docs/stages/stage-g-polish.md` |
| H Delivery | Review fixes, playthrough script, setup, known issues, acceptance checklist, CI checks, pinned Rojo | this report |

Size: about 13,800 lines of Luau in 81 files, plus about 700 lines for the website.

## Acceptance status
See `docs/acceptance-checklist.md`. Summary: 5 criteria pass by automated tests (safety rules, meter
not rewarding darkness, evidence separation, proposal contents, website); the rest are implemented
but need the Studio/device/published runs listed there; deployment steps need the owner.

## Owner actions
1. Run `docs/playthrough.md` (solo, then co-op) and log results; send me the Output for any failure.
2. Publish a private dev experience for real saves (`docs/setup.md`).
3. Enable GitHub Pages and set `ExperienceConfig.CompanionSiteUrl` (`docs/companion-site.md`).
4. Review all player-facing content (dialogue, tips, quiz, pledge, report wording).
5. Supply or approve art and audio to replace placeholders (`docs/known-issues.md`).
6. Decide on publishing only after the above (spec §14, §16).

## Handoff documents
`README.md`, `docs/setup.md`, `docs/architecture.md`, `docs/admin-config-guide.md`,
`docs/playthrough.md`, `docs/acceptance-checklist.md`, `docs/known-issues.md`, `docs/evaluation.md`,
`docs/companion-site.md`, `docs/stages/*`, `tests/README.md`, `assets/manifest.csv`.
