# Full Playthrough Script

Use this to test the whole game end to end. Record each run in the log table at the bottom.
Expected solo time: roughly 60–90 minutes reading every line; about 30 minutes moving quickly.

## Before you start
1. `rojo build -o roblox/the-dark-sky.rbxl` (or `rojo serve` + Connect in Studio).
2. For saves: use the private dev experience (see `docs/setup.md`); a local file uses memory only.
3. Fresh run: Settings → type `RESET` → **Reset MY save**, then Stop and Play.
4. Open **View → Output**. First lines should include `Config check: 0 errors, 0 warnings`,
   `Self tests: N passed, 0 failed (3 outage simulations run in the CLI only)`, `World budget: ...`, `Byers Station ready: 24 fixtures`.

## Solo playthrough
| # | Where | Do | Expected | Pass? |
|---|---|---|---|---|
| 1 | Starlight Hub | Join | Spawn by the red barn; friends nearby; "Playing solo"; quiz "Quick sky check" | |
| 2 | Hub | Answer 3 questions | "Thanks!"; opening dialogue; no answers revealed yet | |
| 3 | Deck | E on the telescope | Sky-view dialogue; Journal evidence "Skyglow through the telescope" | |
| 4 | Hub | Wait | "You got the Lux Lens!" + "Star Journal!"; Lens and Journal buttons appear; friends walk to Lantern Lane | |
| 5 | Lantern Lane | Inspect a light; L toggles Lens | Menu with readings; red glare circles | |
| 6 | Lantern Lane | Question the crossing light, try Turn off | Refused; evidence "Crossing light is needed" | |
| 7 | Lantern Lane | Shield, aim down, dim, warm all three | Meter passes 70 → "Lantern Lane is fixed!" + Compare panel | |
| 8 | Lane | Bike unlock | Bike buttons; R rides, Space brakes, B bell caption; bike parks near lights | |
| 9 | Creek Trail | Ride south to the covered bridge | Rift dialogue, Moon appears; tip "just some broken bulbs" → Doubt it! earns a token | |
| 10 | Bridge | E on the Rift | Arrive in the Glarelands (red tint); Leo arrival dialogue | |
| 11 | Leo's Glare Gate | Inspect, fix all three lights | Leo roars (red discs + banner); Glare slows you briefly; restored at 75; Moon tip "switch EVERY light off" → Doubt it! | |
| 12 | Town (optional) | Return Rift → main road | Main-road echo lamps are now aimed down and warm | |
| 13 | Orion's Spire | Follow the sign; fix floods (aim down, timers), switch off the uplight | Sweep lanes; exit light refuses to go off; restored; TRUE tip → Sounds right earns a token | |
| 14 | Scorpius Meadow | Fix shed flood, trail light, switch off creek accent | Strike circles; restored; tip "blue is the only problem" → Doubt it! | |
| 15 | Cetus Pond | Fix dock (stays on), boathouse, path; switch off fountain | Circles follow you; restored; tip "brighter dock" → Doubt it! | |
| 16 | Journal | Open | Places, evidence, Moon claims, Moon clues (chime, brighter, red glow, 4 guardians) | |
| 17 | Eclipse Throne | Journal-clues dialogue, ride to the throne | Moon descends; reveal | |
| 18 | Throne | Phases 1–4 (QUESTION, SHIELD & AIM, DIM, TIME) | "(N left)" counts down; "Phase complete!"; stair/route lights refuse to turn off; tokens may say "one fewer light needed" | |
| 19 | Throne | Phase 5: three claims | Votes; crown fades; Moon apologizes | |
| 20 | Home | Ending | Teleported to the hub; full starry sky; "Achievement unlocked: Byers Station Night Guardian" | |
| 21 | Home | Post-check | "At the start: X of 3. Now: Y of 3." + answers | |
| 22 | Home | Pledge | Safety note; needs one per place; Star Card; end card with the three lines | |
| 23 | Home | Write a community report | Copy the text; paste into the companion site; Save as PDF | |
| 24 | Anywhere | Keep exploring | Free roam; Rift open; Journal + report still available | |

## Co-op playthrough (Test → Clients and Servers, 2 then 4 players)
| # | Do | Expected | Pass? |
|---|---|---|---|
| 1 | Both join | Both see the quiz; story waits for both (or 150 s) | |
| 2 | Player 2 leaves mid-quiz | Story continues for player 1 | |
| 3 | Player 2 rejoins during Leo | Spawns near the friends in the Glarelands with tools | |
| 4 | One player glared | Other presses H next to them: Glare clears | |
| 5 | Votes | Both vote; 1–1 tie → Moon's tie line, no token | |
| 6 | Journals | Both get the realm, evidence, and token entries | |
| 7 | 4 players at a guardian | Faster cycle (~12 s at Leo), same 3 s warning | |
| 8 | Ending | Both teleported home, both get the achievement; both pledge | |

## Jumping to a part (developers)
Settings → type `RESET` → **Jump to:** Act I, Leo's Glare Gate, Orion's Spire, Scorpius Meadow,
Cetus Pond, or Act III. Everyone is moved to that mission's start with earlier places restored.

## Run log
| Date | Commit | Place / device | Players | Result | Notes |
|---|---|---|---|---|---|
| | | | | | |
