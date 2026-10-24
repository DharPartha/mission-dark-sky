# Stage D — The Four Realms

## What changed
| Area | New / changed |
|---|---|
| Realms | `FixtureConfig.Zones`: **Leo** (glare: shield/aim), **Orion** (sports floods, uplight, timers, exit path), **Scorpius** (spill into meadow, color as one factor, trail light), **Cetus** (pond glare, decorative uplight, dock edge, boathouse) |
| Guardians | `BossConfig`: Leo, Orion, Scorpius, Cetus constellations (traditional star patterns, original creatures), arenas, attacks |
| Boss framework | `BossService` + `src/server/Bosses/` (`Roar`, `Sweep`, `Strike`, `AttackFx`); `GlareService` (temporary Glare + teammate High-five). Replaces `BossAIService` |
| Fairness | Attacks shrink as the zone's score rises; solo: 1.3× slower cycle and +0.8 s warning; bikes park inside an active arena |
| Glarelands | Mirrored sports field + scoreboard, meadow + creek + shed, pond + dock + boathouse, paths, realm signs |
| Town echoes | `FixtureConfig.Echoes`: main-road lamps (Leo), field floodlights (Orion), meadow trail lights + fireflies (Scorpius), dock + pond path lights (Cetus) switch to responsible when the realm is restored |
| Story | Missions `orion`, `scorpius`, `cetus` (travel → arrival → inspect → guardian → restored → Moon tip → next) |
| Moon | 3 more tips (Orion's is **true**: doubting everything is wrong too), evidence for each, red glint + captioned off-key chime at every tip, Moon brightens per realm |
| Clues | `MoonTipsConfig.Clues` recorded in the Journal: guardians' words, the off-key chime, the Moon brightening, the same red glow (for the Act III reveal) |
| Tests | 36 CLI self tests, including per-zone checks: starts polluted, "switch off what you can" alone never restores, responsible fixes always restore, needed lights can't go off |

## Attack guide
| Guardian | Telegraph | Avoid it by |
|---|---|---|
| Leo | Red discs under glaring lights + banner | Standing in shadow; shield/aim lights to shrink the discs |
| Orion | A red lane across the field | Stepping out of the lane |
| Scorpius | A red circle under each player | Stepping out before it lands |
| Cetus | A red circle that follows you, then locks | Moving, then breaking away at the end |
Glare = slower walking + soft washout for 4 s. A teammate can press **H** (gamepad D-pad right, or tap) next to you to High-five it away.

## Studio tests
Use Settings → type RESET → **Jump to:** a realm to test each alone, then play Leo → Cetus in order.

| # | Check | Expected |
|---|---|---|
| 1 | Output | `Config check: 0 errors`, `Self tests: N passed, 0 failed (3 outage simulations run in the CLI only)`, `Byers Station ready: 17 fixtures` |
| 2 | Jump to Orion's Spire | Teleported near the mirrored field; ride/travel step completes; arrival dialogue |
| 3 | Orion attack | Red lane + "Orion is aiming!" banner; standing in it → Glare; lane narrows as you fix lights |
| 4 | Orion fixes | Floods aimed down + timer, uplight switched off (allowed: not needed), exit light can't go off |
| 5 | Orion restored | Guardian turns pale, Moon tip is TRUE: "Sounds right" earns the token |
| 6 | Back in town | Sports-field floodlights now aimed down and warm |
| 7 | Scorpius | Strike circles; shed flood question gives "Spill reaches the meadow"; after restore, town meadow fireflies return |
| 8 | Cetus | Circles follow you, then lock; dock edge light can't go off; restore → pond echo lights fixed |
| 9 | Journal | Places restored, evidence, Moon claims, and **Moon clues** (chime, brighter, red glow, each guardian's words) |
| 10 | Two players | One glared, the other walks up and presses H: Glare clears, "A teammate cleared your glare!" |
| 11 | Solo vs two players | Solo attacks come less often with longer warnings |

## Known limitations
- Guardian "bodies" are star figures in the sky; there are no rigged meshes (owner art needed).
- Attack markers and flashes are server-side parts; with very high latency the marker may lag slightly.
- After Cetus the story currently ends in free roam; the Moon reveal and finale are Stage E.
