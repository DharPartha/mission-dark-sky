# Stage E — Moon Reveal, Finale, Ending, and Pledge

## What changed
| Area | New / changed |
|---|---|
| Story | Act I Rift tip ("just broken bulbs", misleading); Act III mission `finale`: Journal clues → Eclipse Throne → reveal → 5 phases → Moon calmed → home → pledge |
| Phases | New step kinds `phase` (QUESTION / SHIELD & AIM / DIM / TIME goals on the throne lights), `claims` (CHOOSE WISELY: three Moon claims), `ending`, `pledge` (`Shared/FinaleRules`) |
| Moon | `BossConfig.Moon` (crown of stolen glare, tracking strike); descends to the throne; attacks pause during votes/dialogue; Doubt Tokens weaken her attacks and can shorten phases (never required) |
| Tips | Now 10 total, the spec baseline: 6 misleading, 4 true. New evidence: skyglow seen through the telescope, timer used, fixes reaching town |
| Ending | Rift closes, everyone home at the Starlight Hub, full starry sky in town, Moon back in the sky as a gentle silver, achievement **Byers Station Night Guardian** |
| Pledge | `PledgeConfig` + `PledgeService` + `Shared/PledgeRules`: at least one safe preset action per place (Home, School, Community), safety reminder first, saved as ids only; Star Card in the Journal |
| End card | The three spec lines, the achievement, then the Star Card; free roam afterwards with the Rift reopened |
| World | Eclipse Throne dais + steps past the mirrored creek, throne lights, path and sign |
| Tests | 39 CLI self tests: finale phases solvable with legal verbs, safety lights intact, token discount never reaches zero, strict pledge validation, Eclipse zone balance |

## Finale walkthrough
| Phase | Goal | Notes |
|---|---|---|
| 1 QUESTION | Switch off both sky beams | Stair and route lights refuse to switch off |
| 2 SHIELD & AIM | Shield all 3 floods and aim them Down | 2 tokens: only 2 needed |
| 3 DIM | Dim all 3 floods to recommended (50%) | 3 tokens: only 2 needed |
| (vote) | "Sensors and timers..." | TRUE claim |
| 4 TIME | Floods 2 and 3 on Motion or a curfew timer | Safety lights stay "On all night" |
| 5 CHOOSE WISELY | Vote on 3 claims (clouds, brightest, one town) | 4 tokens: first claim skipped; any answers finish the fight |

## Studio tests
Settings → type RESET → **Jump to: Act III: The Moon's Secret** (you start near Cetus Pond).

| # | Check | Expected |
|---|---|---|
| 1 | Output | `Config check: 0 errors`, `Self tests: N passed, 0 failed (3 outage simulations run in the CLI only)`, `Byers Station ready: 24 fixtures` |
| 2 | Journal dialogue, ride to the throne sign | Moon glides down to the throne; reveal dialogue |
| 3 | Each phase | Objective shows "(N left)", count drops as you fix; "Phase complete!" |
| 4 | During phases | Red circles follow you (Moon flares); paused during votes |
| 5 | Try switching off the stair light | Refused (safety) |
| 6 | Claims | Three votes with follow-ups; then the crown fades and the Moon apologizes |
| 7 | Ending | Everyone teleported to the Starlight Hub; town sky full of stars; "Achievement unlocked" |
| 8 | Pledge | Safety note on top; can't submit without one action per place; max 3 per place |
| 9 | After pledging | Star Card shows choices; end card with the three lines and the achievement |
| 10 | Journal | "My Night Sky Pledge" entry and a Star Card button |
| 11 | With 0 tokens (reset save first) | Finale still completes |
| 12 | Rejoin mid-finale (dev experience) | Resumes at the phase; earlier phases' lights are rebuilt fixed |

## Known limitations
- The post-adventure knowledge check, community report, and companion website arrive in Stage F (the ending currently goes straight to the pledge).
- The Moon is a glowing sphere with a star crown; no animated character model yet.
