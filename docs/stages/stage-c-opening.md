# Stage C — Opening and Byers Station

## What changed
| Area | New / changed |
|---|---|
| World | `src/server/World/`: `Parts`, `StreetBuilder`, `TownBuilder`, `GlarelandsBuilder`, `FixtureBuilder`, `SkyBuilder`, `NpcBuilder`, `BikeModel`; `WorldBuilder` now only orchestrates |
| Layout | `Config/WorldConfig`: Starlight Hub barn + telescope deck, Lantern Lane, main road, school, library, community center, parking, sports fields, pond + dock, creek, meadow, creek trail, covered bridge with Rift, signposts; Glarelands arrival + mirrored Leo street |
| Story | `MissionConfig`: Act I (pre-check quiz → opening → telescope → tools → Lantern Lane tutorial → bikes → ride to bridge → Rift → Glarelands) then Leo |
| Zones | `Home` (Lantern Lane tutorial, threshold 70) and `Leo` (Glarelands mirror, threshold 75) |
| New step kinds | `quiz`, `interact`, `grant`, `reach` (+ optional `companions`, `activeZone`, `opensRift`) |
| Services | `NavigationService` (checkpoints, Get unstuck, reach targets, Rift), `BikeService`, `QuizService`, `GuidanceService` (adaptive hints, Hint button, guide beam) |
| Saves | Schema v2: `unlocks` (luxLens, journal, bike); checkpoints store step ids; v1 migration |
| Client | `BikeController`, `QuizController`, `NavigationController` (region + guide beam), Hint/Unstuck buttons, tools appear when unlocked, Meter follows the active zone, Glarelands tint, dev "Jump to" mission buttons |

## Bikes
Ride mode, not physics: a bike is welded to you and the server sets speed. PC: R ride/get off,
Shift boost, Space brake, B bell. Gamepad: L1, R2, L2, D-pad up. Touch: big buttons on the left.
No riding within 26 studs of a puzzle light (auto-parks). The headlamp is warm, shielded, aimed down.

## Studio tests (local file)
`rojo build -o roblox/the-dark-sky.rbxl`, open, **Play**.

| # | Do | Expected |
|---|---|---|
| 1 | Output | `Config check: 0 errors`, `Self tests: 31 passed`, `Byers Station ready: 6 fixtures`, no red errors |
| 2 | Spawn | At the Starlight Hub (red barn, telescope deck), friends nearby; quiz panel "Quick sky check" |
| 3 | Answer 3 questions | "Thanks!", opening dialogue plays; objective "Look through the telescope on the deck." |
| 4 | Press E at the telescope | Sky-view dialogue; then "You got the Lux Lens!" / "Star Journal!"; Lens and Journal buttons appear; friends move to Lantern Lane |
| 5 | Inspect a Lantern Lane light, fix all three (shield, aim down, dim, warm) | Meter shows Lantern Lane; reaching 70 shows "Lantern Lane is fixed!" + Compare panel |
| 6 | Bike | "You got a bike!"; bike buttons on the left; R rides (faster), Space brakes, B rings (caption) |
| 7 | Ride near a fixture | "Bike parked: puzzle area ahead." |
| 8 | Follow the Creek Trail sign south | Reach the covered bridge: Rift dialogue, Moon appears, orange Rift opens inside the bridge |
| 9 | Press E at the Rift | Arrive in the Glarelands (dark, red tint); Leo mission starts; friends there |
| 10 | Leo as before | Inspect → roar/Glare → fix → restored → Moon tip → done; "Return to Byers Station" Rift works |
| 11 | Wait 45 s on a step without progress | A friend offers a hint; on ride/reach steps a warm guide beam appears after 60 s |
| 12 | Hint button | Hint now (and the guide beam on ride steps) |
| 13 | Settings → Get unstuck | Back to the last checkpoint (hub, lane, bridge, or Glarelands arrival) |
| 14 | Settings → type RESET → Jump to: Leo's Glare Gate | Everyone teleported to the Glarelands at the Leo mission, tools unlocked |
| 15 | Phone emulator | Bike buttons, quiz buttons, Hint all tappable; nothing overlaps the jump button |

Two players: both answer the quiz (the story waits up to 150 s); a late joiner gets the tools the team already has.

## Known limitations
- The rider's legs still play the walking animation on the bike (placeholder).
- Pond, creek, and meadow are flat colored parts (no terrain water); players can walk on them.
- The Glarelands only mirror Lantern Lane so far; other landmark mirrors come with their realms in Stage D.
- Sports-field floodlights are unlit placeholders until Orion's realm.
- No audio yet; the bell and important events show captions.
