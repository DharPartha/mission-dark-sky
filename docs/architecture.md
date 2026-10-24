# Architecture (Stage G)

One Roblox place. Server owns progress, validation, scoring, and boss state. Clients present
state and send requests. Content lives in config modules that a non-programmer can edit.

```
ReplicatedStorage.DarkSky
  Config/   ExperienceConfig, FeatureFlags, Tuning, FixtureConfig, BossConfig, MissionConfig,
            DialogueConfig, MoonTipsConfig, UIText, BubbleTheme, AnalyticsConfig, WorldConfig, QuizConfig,
            PledgeConfig, ReportConfig
  Shared/   Types, Text, DarknessMath, FixtureRules, ConfigValidator, Net,
            ProfileSchema, SessionLock, RateLimiter, FinaleRules, PledgeRules, ReportBuilder, PartyRules
  Remotes/  (created by server)  State/  (created by server; attributes only)
ServerScriptService.DarkSky
  Bootstrap.server   Services/ WorldBuilder, WorldStateService (team), ProfileService (personal saves),
                     ProgressionService (missions), DialogueService, FixturePuzzleService,
                     BossService, GlareService, MoonTipService, RemoteGuard, Environment, DevService,
                     MetricsService, NavigationService, BikeService, QuizService, GuidanceService,
                     PledgeService
  Bosses/   AttackFx, Roar, Sweep, Strike (guardian attack behaviors)
  World/    Parts, StreetBuilder, TownBuilder, GlarelandsBuilder, FixtureBuilder, SkyBuilder,
            NpcBuilder, BikeModel
  Persistence/ProfileStore   ServerConfig/DevConfig (server-only)   Tests/SelfTests
StarterPlayerScripts.DarkSky
  Main.client        Controllers/ UiKit, ClientSettings, ScreenManager, QualityController, HUDController,
                     BubbleRenderer, FixtureMenuController, LuxLensController, SkyFXController,
                     MoonTipController, JournalController, NavigationController, BikeController,
                     QuizController, PledgeController, ReportController, InputController, SettingsSync
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
| SaveSettings | C→S | { reducedMotion, largeText, highContrast, quality } | rate limit, `ProfileSchema.cleanSettings` (known names, allowed values) |
| ReportGenerated | C→S | – | rate limit; counts the event only (the report text never leaves the device) |
| PledgeSubmit | C→S | { category: { actionId } } | rate limit, pledge offered, `PledgeRules.clean` (known ids, 1–3 per place, no repeats) |
| OpenFixtureMenu, Notice, Dialogue, GlareEvent, ShowCompare, BellRang | S→C | ids/keys only | – |

## Guardians
`BossService` runs one encounter per active `restore` step: wait → telegraph (banner to nearby
players, ground markers, constellation flare) → attack behavior → `GlareService.apply` for anyone
hit. Intensity = clamp((100 − zone score) / 80, 0.2, 1). Solo: slower cycle, longer telegraph.
Town echoes (`FixtureConfig.Echoes`) switch to their responsible state when their zone is restored.

## Finale
`phase` steps complete when `FinaleRules.metCount` reaches `FinaleRules.required` (one fewer with
enough Doubt Tokens, never zero). `claims` runs several Moon votes in a row and then calms the Moon.
Mid-finale saves resume by rebuilding earlier phases with `FinaleRules.applyGoal`; a `seeding` flag
stops those rebuild changes from advancing steps. `ending` closes the Rift, teleports everyone home,
and grants the achievement; `pledge` waits for every player (or a timeout) and then shows the end card.

## Community report and companion site
`ReportBuilder` (shared, pure) writes `DARKSKY-REPORT v1` text on the player's device from their own
replicated journal, pledge, and three preset choices. `site/` (static, GitHub Pages) parses it with
`parser.js` and prints with the browser's print dialog. See `docs/companion-site.md`.

## Evaluation
Anonymous aggregate events only; targets and formulas in `docs/evaluation.md`.

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
If a save can't be read at join, the server retries every 60 s (5 times) and merges the session's
progress into the recovered save (`ProfileSchema.merge`). Team rewards that happen while a save is
still loading are queued and applied when it loads.

## Co-op
Party size feeds `PartyRules` (boss timing, vote time) every cycle. Steps that wait for everyone
re-check when a player leaves. First spawns go to `State.TeamStation`; respawns to the player's
last checkpoint.

## Environments and test tools
`local` (PlaceId 0) / `dev` (listed PlaceIds) / `production` (everything else). Test tools need the
flag, a non-production environment, an authorized developer, and the typed confirm word.

## Analytics
Allow-listed anonymous events only (`AnalyticsConfig`), one number at most, no personal data.
