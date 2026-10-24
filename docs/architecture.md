# Architecture (Stage D)

One Roblox place. Server owns progress, validation, scoring, and boss state. Clients present
state and send requests. Content lives in config modules that a non-programmer can edit.

```
ReplicatedStorage.DarkSky
  Config/   ExperienceConfig, FeatureFlags, Tuning, FixtureConfig, BossConfig, MissionConfig,
            DialogueConfig, MoonTipsConfig, UIText, BubbleTheme, AnalyticsConfig, WorldConfig, QuizConfig
  Shared/   Types, Text, DarknessMath, FixtureRules, ConfigValidator, Net,
            ProfileSchema, SessionLock, RateLimiter
  Remotes/  (created by server)  State/  (created by server; attributes only)
ServerScriptService.DarkSky
  Bootstrap.server   Services/ WorldBuilder, WorldStateService (team), ProfileService (personal saves),
                     ProgressionService (missions), DialogueService, FixturePuzzleService,
                     BossService, GlareService, MoonTipService, RemoteGuard, Environment, DevService,
                     MetricsService, NavigationService, BikeService, QuizService, GuidanceService
  Bosses/   AttackFx, Roar, Sweep, Strike (guardian attack behaviors)
  World/    Parts, StreetBuilder, TownBuilder, GlarelandsBuilder, FixtureBuilder, SkyBuilder,
            NpcBuilder, BikeModel
  Persistence/ProfileStore   ServerConfig/DevConfig (server-only)   Tests/SelfTests
StarterPlayerScripts.DarkSky
  Main.client        Controllers/ UiKit, ClientSettings, ScreenManager, QualityController, HUDController,
                     BubbleRenderer, FixtureMenuController, LuxLensController, SkyFXController,
                     MoonTipController, JournalController, NavigationController, BikeController,
                     QuizController
Workspace.DarkSkyWorld  (built at runtime; zones/fixtures/NPCs tagged with CollectionService)
```

## Data flow
1. Player triggers a fixture's **Inspect** ProximityPrompt (server event) → evidence recorded,
   server opens that player's fixture menu; an `inspect` mission step advances.
2. Menu button → `FixtureAction(fixtureId, verb, option)`.
3. `FixturePuzzleService` checks types/lengths, fixture and verb exist, player alive and within
   `Tuning.Interact.MaxActionDistance`, cooldown, quest phase. Then `FixtureRules.apply` enforces
   safety (no switching off needed lights, DIM floor, safety lights stay on all night).
4. `GameStateService.setFixtureState` writes attributes, updates the world lights, and
   recomputes the zone with `DarknessMath.summarizeZone` (one 0–100 score).
5. Clients react to the score attribute: meter, sky (stars, haze, tint, bloom), fireflies.
6. `ProgressionService` restores the realm when score ≥ `restoreThreshold` **and** safe paths are lit,
   then runs the Moon tip vote.

## Remotes (all validated server-side)
| Remote | Direction | Payload | Server checks |
|---|---|---|---|
| ClientReady | C→S | – | rate limit; first one starts the story from that player's save |
| FixtureAction | C→S | fixtureId, verb, option (strings ≤ 40 chars) | rate limit + listed above |
| MoonVote | C→S | "agree" \| "doubt" | rate limit, a vote is open, value in set |
| DevRequest | C→S | action, confirm word, missionId? | rate limit, flag, environment not production, developer, confirm word |
| BikeRequest | C→S | "toggle" \| "boost" \| "bell" | rate limit, bike unlock, alive, not near a fixture, cooldowns |
| QuizSubmit | C→S | quizId, answers {number} | rate limit, quiz active, not answered before, length and range |
| RequestHint, Unstuck | C→S | – | rate limit |
| OpenFixtureMenu, Notice, Dialogue, GlareEvent, ShowCompare, BellRang | S→C | ids/keys only | – |

## Guardians
`BossService` runs one encounter per active `restore` step: wait → telegraph (banner to nearby
players, ground markers, constellation flare) → attack behavior → `GlareService.apply` for anyone
hit. Intensity = clamp((100 − zone score) / 80, 0.2, 1). Solo: slower cycle, longer telegraph.
Town echoes (`FixtureConfig.Echoes`) switch to their responsible state when their zone is restored.

## World and regions
One place. Byers Station around the origin; the Glarelands mirror at X + 4000 (`WorldConfig`).
The covered-bridge Rift teleports between them (town side opens through the story; the Glarelands
side is always open). Teleports request streaming around the destination first. The Meter, Compare
panel, and sky follow `State.ActiveZone`, set by the current mission step.

Clients receive text **keys**, not text, so localization stays on the client.

## Scoring (DarknessMath)
Per fixture: glare, uplight (sky glow), over-lighting (above recommended brightness), and blue
light, each 0–1, weighted by `Tuning.Score.Weights` and scaled by the schedule's on-fraction.
Zone score = `100 × (1 − averageHarm × HarmScale)`. Safety is a constraint enforced by
`FixtureRules`, so turning lights off can never be the winning move.

Balance (CLI): start **30**, every light shielded **60**, every light shielded + aimed down +
dimmed to recommended + 3000K **97**. Restore threshold **75**.

## Persistence
`ProfileService` loads each player's profile through `ProfileStore` (DataStore `DarkSkyProfiles`,
scope `dev` or `prod`; memory-only in unpublished files). Records carry a session lock refreshed by
autosave; a live lock from another server blocks loading (player plays unsaved), a stale one (>300 s)
is taken over. Read failures retry with backoff and never write defaults. Corrupt data is backed up
to `<key>_backup_<time>` before replacement. Newer-version data is never overwritten.
Saves: checkpoints (merged within 20 s), autosave every 90 s, on leave (lock released), on shutdown.

## Environments and test tools
`local` (PlaceId 0) / `dev` (listed PlaceIds) / `production` (everything else). Test tools need the
flag, a non-production environment, an authorized developer, and the typed confirm word.

## Analytics
Allow-listed anonymous events only (`AnalyticsConfig`), one number at most, no personal data.
