# The Dark Sky — Full Game Plan (for owner review)

Source of truth: `docs/specs/The_Dark_Sky_Complete_Claude_Build_Spec.txt` (replaces the PDF where they differ).
Status: **draft, not approved.** Nothing below is implemented yet.

## Decisions already made
| # | Decision |
|---|---|
| 1 | New text spec wins: 4 realms (Leo, Orion, Scorpius, Cetus), no Ursa Major, no Skull Crusher |
| 2 | After each stage: I commit, run CLI checks + Rojo build, give you test steps; you paste the Studio Output |
| 3 | Saves: real DataStore on a private **development** experience; unpublished Studio runs use labelled memory-only saves |
| 4 | Companion site: print-to-PDF in the browser, no libraries, nothing uploaded |
| 5 | Town name: Byers Station everywhere |

## Stage A — Audit (done, read-only)
Branch `m1-leo-vertical-slice`, clean tree, ~5,400 lines, origin `aiklox-in/mission-dark-sky`. Tools: Rojo 7.7.1, Luau CLI, Node 26, Studio.

| Existing piece (M1) | Keep? | Becomes |
|---|---|---|
| Config-first content, `Text`, `ConfigValidator`, self tests | Keep, extend | Same pattern for all new content |
| `DarknessMath`, `FixtureRules` (5 verbs + safety rules) | Keep | Shared by tutorial, all realms, finale |
| `FixturePuzzleService` (validated actions, undo) | Keep, generalize | Works for any zone; adds rate limits |
| `GameStateService` (one shared zone) | Split | `WorldStateService` (shared per server) + `ProfileService` (personal, saved) |
| `QuestService` (Leo state machine) | Rewrite as data-driven | `ProgressionService` with mission steps from `MissionConfig` |
| `BossAIService` (Leo roar) | Generalize | `BossService` + one behavior module per boss |
| Lantern Lane + 3 fixtures | Keep, move | Act I tutorial street in Byers Station |
| HUD, bubbles, fixture menu, Lux Lens, sky FX, Moon vote, settings | Keep, extend | Adds Journal, map, bike controls, quizzes, report |
| `roblox/*.rbxl` old Smart Town places | Untouched | — |

## Design choices to approve
1. **One place, two regions.** Byers Station near the origin; Glarelands is a distorted mirror built far away (offset ~3,000 studs) so both stream independently. The covered bridge Rift teleports between them. Each realm sits in the Glarelands copy of its town landmark; restoring it also fixes the matching town lights.
2. **Realm ↔ landmark:** Leo = main road + parking (glare); Orion = sports fields + community building (floodlights, schedules); Scorpius = creek trail + meadow (spill, color); Cetus = pond + dock (reflections, decorative lights). Eclipse Throne finale above the bridge.
3. **Personal vs shared.** World and puzzle state are shared by everyone in the server (the party). Progress (realms done, journal, achievements, pledge, quiz) is personal and saved per player. The first player's save sets the server's starting world; everyone present when a realm is restored gets credit; players who already finished a realm can replay it to help, with no loss. UI labels say "Team" or "You".
4. **Bicycle.** A simple, low-physics ride mode: the bike model is welded to the character, and the server sets speed within limits (no free-flying constraints to get stuck). Shift/ButtonR2 boost, Space/ButtonB brake, E dismount; on-screen Boost/Brake/Bell for mobile. Auto-dismount near puzzles and in boss arenas. A "Get unstuck" button returns you to the last checkpoint. Shielded warm downward headlamp.
5. **Bosses** share one framework: readable telegraph (banner + caption + shape on the ground) → glare/sweep → temporary washout or slowdown → recovery in safe shadow or by a teammate's high-five. Puzzle phases are won by fixing fixtures, never by damage. Party size scales telegraph timing and the number of fixtures needed.
6. **Moon finale** at the Eclipse Throne: 5 phases (QUESTION, SHIELD & AIM, DIM, TIME, CHOOSE WISELY). Each phase is a small fixture puzzle or an evidence choice. Doubt Tokens shorten a phase (fewer fixtures needed) but are never required.
7. **Learning.** 3-question pre-check before Act I and the same 3 after the ending (preset choices, no free text). Adaptive hints: friends' hints get less automatic as you solve correctly first try; a Hint button always works.
8. **Report.** Built from personal journal data into a versioned plain-text format (`DARKSKY-REPORT v1`) shown in a selectable, copyable box. Reflection and recommendation use preset choices (no free text, no personal data). The site URL is a config value left empty until you deploy; the game shows "copy this text" instructions either way.
9. **Companion site** in `site/` (plain HTML/CSS/JS), deployed by a GitHub Actions Pages workflow. It parses the pasted report, shows errors for bad input, formats a print layout, and has a "Save as PDF" button that opens the print dialog. It works offline after loading and has no analytics. Parser tests run with `node --test` (Node is a dev tool only, not a dependency).
10. **Persistence** (`ProfileService`): `UpdateAsync` with a session lock, retries with backoff, schema version and migrations. A failed read never overwrites a save: the player plays in "unsaved" mode with a warning. Autosave at checkpoints plus on leave and on server close.
11. **Test reset:** only works in Studio or the dev experience (PlaceId set in config), **and** only for user IDs on a dev allowlist. It needs a typed confirm, shows a red "TEST MODE" banner, and is never reachable on the public experience.
12. **Analytics:** anonymous aggregate events only (funnel steps, quiz score bands, decision correctness), behind a feature flag. No names, no free text.
13. **Audio:** `AudioConfig` with empty asset IDs (owner supplies sounds). Every important sound already has a caption or visual cue, so the game is complete without audio.
14. **Quality tiers** Low/Mid/High (auto + manual): shadows, particles, effect density.

## Stages (one Git checkpoint and one Studio test hand-off each)
| Stage | Delivers | You test |
|---|---|---|
| **B Foundations** | `MissionConfig` + `ProgressionService` (data-driven steps), `ProfileService` (DataStore + memory fallback, migrations), `WorldStateService`, remote rate limits, dev-auth reset, `Analytics`, UI framework (screen manager, HUD shell, Journal shell), quality tiers. M1 behavior still playable through the new framework | Leo slice still works; save/rejoin in the dev experience; reset rejected for non-dev |
| **C Opening + Byers Station** | Full town (homes, school, library, community building, fields, pond, creek trail, parking, covered bridge, Starlight Hub with telescope), opening sleepover scene, pre-check quiz, bike, companions with adaptive hints, Lux Lens + Journal handout, 3 tutorial fixtures, ride to the bridge, Rift to Glarelands | Act I start to the Rift on PC and phone emulator |
| **D Four realms** | Glarelands mirror; Leo (move + polish), Orion, Scorpius, Cetus: each with puzzle, evidence, boss behavior, checkpoints, restoration that also fixes town lights; Moon tips spread across realms; Moon foreshadowing | Each realm alone (dev "jump to realm"), then in order |
| **E Finale + ending** | Journal reveal, Eclipse Throne, 5-phase Moon fight, rift closes, restored town, stargazing ending, end card, "Byers Station Night Guardian", Night Sky Pledge | Finale with 0 and with all Doubt Tokens |
| **F Learning + report + site** | Post-check, aggregate events, report schema/builder, copy UI, `site/` with parser, print layout, tests, Pages workflow, URL config | Copy a report into the local site and print to PDF |
| **G Co-op + polish** | Party scaling, late join/disconnect/respawn, save recovery cases, mobile/gamepad/accessibility pass, performance pass, regression self tests | 2–4 player Studio test, device emulator, reduced motion/contrast |
| **H Delivery** | Full playthrough script, bug fixes, docs (architecture, setup, DataStore, Pages, admin config, known issues), acceptance checklist with pass/fail/not-tested | Full solo playthrough, then co-op |

## Owner inputs needed (not blocking; placeholders until supplied)
- Review of all dialogue, Moon claims, quiz questions, pledge items, and any real-world facts.
- Dev experience PlaceId and your Roblox user ID(s) for the dev allowlist (Stage B).
- Optional audio assets and higher-polish art for the opening, Leo, and the finale.
- Enable GitHub Pages (source: GitHub Actions) on `aiklox-in/mission-dark-sky`, then the deployed URL for the config (Stage F).

## Risks
- Large scope: roughly 15–20k lines across stages. Primitive-part art reads as "good placeholder", not final polish.
- Nothing is Studio-verified until you test it; bugs from untested stages can stack, which is why every stage gets a hand-off.
- DataStore behavior can only be verified on the published dev experience.
- Copy to clipboard: Roblox cannot write to the clipboard; players select the text (Ctrl/Cmd+C, or long-press on mobile).
