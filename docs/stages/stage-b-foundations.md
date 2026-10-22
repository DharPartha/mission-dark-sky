# Stage B — Foundations

## What changed
| Area | New / changed | Purpose |
|---|---|---|
| Story runner | `ProgressionService` + `Config/MissionConfig` (replaces `QuestService`) | Missions are data: dialogue, inspect, restore, moonTip steps |
| Shared world | `WorldStateService` (was `GameStateService`) | Per-server team state only |
| Saves | `ProfileService`, `Persistence/ProfileStore`, `Shared/ProfileSchema`, `Shared/SessionLock` | Personal progress, DataStore with locks, retries, migrations, corrupt-save backup |
| Security | `RemoteGuard`, `Shared/RateLimiter` | Rate limit + error isolation on every client request |
| Dev tools | `Environment`, `DevService`, `ServerConfig/DevConfig` | Reset world / reset my save, dev-only, typed confirm |
| Analytics | `MetricsService`, `Config/AnalyticsConfig` | Anonymous allow-listed events (printed in local files) |
| Moon vote | `MoonTipService` | Reusable team vote |
| Client | `ScreenManager`, `JournalController`, `QualityController`, HUD chips/dev banner | One panel at a time, Star Journal, graphics tiers, save status |

## Shared vs personal
- **Team (shared):** lights, Darkness score, evidence found, current mission step.
- **You (saved):** checkpoints, missions done, realms restored, journal, Doubt Tokens.
- The first player to join sets the starting point from their save. Everyone present gets rewards.

## Studio tests

### B1 — Local file (no DataStore)
`rojo build -o roblox/the-dark-sky.rbxl`, open it, **Play**.

| Check | Expected |
|---|---|
| Output | `Environment local, saves: memory`, `Config check: 0 errors`, `Self tests: 29 passed, 0 failed`, `Byers Station ready: 3 fixtures` |
| Bottom-right chips | "Doubt Tokens: 0" and "⚠ Test file: progress is not saved" |
| Bottom red bar | "TEST MODE: local" |
| Leo flow (as in M1) | Intro → inspect → fix → restored → Moon vote → "Leo's realm restored!" |
| Journal button | Before inspecting: empty message. After: evidence lines, "★ Lantern Lane: Leo's Glare Gate: Darkness 30 before, 9x after", Moon claim result |
| After the vote | Doubt Tokens chip goes to 1 if you picked Doubt it! |
| Settings → Graphics | Cycles Auto/Low/Medium/High; Low turns off bloom and fireflies thin out |
| Settings → type RESET → Reset world | World polluted again, quest at "inspect", notice "Realm reset for testing." |
| Reset without typing RESET | Notice "Type the confirm word first." |
| Panels | Opening Journal closes Settings/Compare (only one at a time) |
| Output when spamming buttons | At most one "Rate limit: dropped..." line per burst, no errors |
| Output analytics lines | `[DarkSky] analytics session_start`, `mission_step`, `realm_restored ...` |

### B2 — Development experience (real saves)
Do this once:
1. **File → Publish to Roblox As → Create new experience**, name it e.g. "The Dark Sky (DEV)", keep it **private**.
2. **Game Settings → Security → Enable Studio Access to API Services: ON.**
3. Put its PlaceId and your Roblox user id in `src/server/ServerConfig/DevConfig.luau` (`DevPlaceIds`, `DevUserIds`). Tell me the numbers and I can add them.

Then:
| Check | Expected |
|---|---|
| Output | `Environment dev, saves: datastore` |
| Chip | "💾 New save started" first time, "Progress saves automatically" after rejoin |
| Finish Leo, Stop, Play again | Starts in free roam with Leo already restored (blue), journal kept, tokens kept |
| Quit mid-Confront, Play again | Resumes at "Fix the glare" with the lights polluted |
| Settings → RESET → Reset MY save → Stop → Play | Starts fresh at the intro |
| Remove your id from `DevUserIds` | No red bar, no dev buttons; forced requests print "Dev request refused" |

### B3 — Two players (Test → Clients and Servers, 2)
| Check | Expected |
|---|---|
| Both chips | Each shows its own tokens/save |
| Player 1 fixes Leo | Both journals get the realm entry; both get the token if the team doubts |

## Not covered yet
DataStore outage behavior is covered by CLI tests only (fake store); live outage can't be forced in Studio.
Players still loading their save when a reward happens don't receive it (rare; revisit in Stage G).
