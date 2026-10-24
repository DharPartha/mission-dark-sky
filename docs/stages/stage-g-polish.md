# Stage G — Co-op, Recovery, Accessibility, Performance, Regression

## What changed
| Area | Change |
|---|---|
| Party size | `Shared/PartyRules`: solo = slower boss cycles + longer warnings; teams of 3–4 up to 15% faster cycles, **never shorter warnings**; votes get +5 s per extra player (max +15 s). Re-read every cycle, so joins/leaves adjust live |
| Role sharing | Teams of 2+ get a tip when a guardian or finale phase starts: scout with the Lux Lens / fix lights / watch for warnings. Objective panel shows "Team of N" or "Playing solo" |
| Leavers | Quiz and pledge steps re-check "everyone" when someone leaves, so nobody waits for a player who is gone; votes already re-count |
| Late join | First spawn goes to the team's current location (`TeamStation`); tools catch up (Stage C); team rewards that happen while a save is still loading are queued and applied on load |
| Respawn | Respawns return to your last checkpoint; Glare and bike state reset with the new character |
| Save recovery | If a save could not be read at join (outage or another server's lock), the server retries every 60 s up to 5 times and **merges** this session's progress into the recovered save (`ProfileSchema.merge`: union of flags, larger token count, first quiz answer kept, journal combined) |
| Settings | Schema v3 `settings`: reduced motion, large text, high contrast, graphics quality follow the player (`SettingsSync`, validated by `ProfileSchema.cleanSettings`) |
| Controls | Keyboard: L Lux Lens, J Journal, G hint (E interact, F talk, R ride, Shift boost, Space brake, B bell, H high-five). Gamepad: D-pad left Lens, D-pad down Journal, L1 ride, R2 boost, L2 brake, D-pad up bell, X interact, Y talk, D-pad right high-five, B closes panels; panels open with the first button selected |
| Performance | Client shadow budget: only the nearest 12 (High) / 6 (Mid) / 0 (Low) spotlights cast shadows; quality init never blocks UI; server prints `World budget: N parts, N lights` at start |
| Tests | 44 Luau self tests (+ merge, settings, v2→v3, party rules, solo completability) and 11 website tests |

## Spec testing matrix (§15) — status
| Case | How it is covered | Status |
|---|---|---|
| Fresh / returning player | CLI: ProfileStore new + cross-server load | Automated ✓ |
| Corrupted / missing save | CLI: backup then replace; no replace if backup fails | Automated ✓ |
| Temporary DataStore read/write failure | CLI: retries, outage never writes; recovery merge | Automated ✓ (live outage: not testable locally) |
| Schema migration | CLI: v0→v3, v1→v3, v2→v3 | Automated ✓ |
| Solo full playthrough | Manual Studio script in Stage H | Not yet run |
| Co-op full playthrough, disconnect, late join, party size | Studio "Clients and Servers" (2–4) checklist below | Not yet run |
| Each boss valid / invalid / repeated / out-of-range / checkpoint | CLI: per-zone rules + rate limiter; Studio checklist | Partly automated |
| Safe vs "turn everything off" | CLI: per-zone and finale tests | Automated ✓ |
| Mobile / PC / gamepad / scaling / reduced motion / contrast / captions | Studio device emulator + gamepad | Not yet run |
| Report copy/paste, malformed input, PDF, print, offline, no transmission | Site tests + browser check (Stage F) | Automated ✓ / browser-checked |
| Dev reset authorization, non-dev rejection, production safety | `Environment` rules; Studio checklist | Not yet run |

## Studio checklist (Test → Clients and Servers)
| # | Setup | Do | Expected |
|---|---|---|---|
| 1 | 1 player | Start | Objective shows "Playing solo"; Leo roars about every 18 s with ~3.8 s warning |
| 2 | 2 players | Reach Leo's confront | "Team tip" notice; roars every 14 s with a 3 s warning (4 players: about 12 s); "Team of 2" |
| 3 | 2 players | Player 2 leaves during the pre-check quiz before answering | Story continues for player 1 right away |
| 4 | 2 players | Player 2 joins mid-Leo | Player 2 appears near the friends in the Glarelands with Lens, Journal, bike |
| 5 | Any | Reset character (Esc → Reset) in a realm | Respawn back at that realm's checkpoint, not the hub |
| 6 | Any | Toggle Large text + Reduced motion, Stop, Play again (dev experience) | Settings come back on |
| 7 | PC | Press L, J, G | Lens toggles, Journal opens, a friend gives a hint |
| 8 | Gamepad | D-pad left, D-pad down, open Settings | Lens toggles, Journal opens with the first button selected; B closes |
| 9 | Phone emulator | Play Act I | All buttons reachable; bike buttons don't cover the thumbstick |
| 10 | Output | Start | `World budget: ... parts, ... lights` line |

## Known limitations
- Live DataStore outages and lock conflicts can only be checked on the published dev experience.
- FPS has not been measured on any device; Stage H records real numbers if you run the profiler.
