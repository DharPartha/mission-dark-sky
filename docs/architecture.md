# Architecture (Milestone 1)

One Roblox place. Server owns progress, validation, scoring, and boss state. Clients present
state and send requests. Content lives in config modules that a non-programmer can edit.

```
ReplicatedStorage.DarkSky
  Config/   ExperienceConfig, FeatureFlags, Tuning, FixtureConfig, BossConfig,
            DialogueConfig, MoonTipsConfig, UIText, BubbleTheme
  Shared/   Types, Text, DarknessMath, FixtureRules, ConfigValidator, Net
  Remotes/  (created by server)  State/  (created by server; attributes only)
ServerScriptService.DarkSky
  Bootstrap.server   Services/ WorldBuilder, GameStateService, DialogueService,
                     FixturePuzzleService, BossAIService, QuestService
  Tests/SelfTests
StarterPlayerScripts.DarkSky
  Main.client        Controllers/ UiKit, ClientSettings, HUDController, BubbleRenderer,
                     FixtureMenuController, LuxLensController, SkyFXController, MoonTipController
Workspace.DarkSkyWorld  (built at runtime; zones/fixtures/NPCs tagged with CollectionService)
```

## Data flow
1. Player triggers a fixture's **Inspect** ProximityPrompt (server event) → evidence recorded,
   server opens that player's fixture menu, quest moves Investigate → Confront.
2. Menu button → `FixtureAction(fixtureId, verb, option)`.
3. `FixturePuzzleService` checks types/lengths, fixture and verb exist, player alive and within
   `Tuning.Interact.MaxActionDistance`, cooldown, quest phase. Then `FixtureRules.apply` enforces
   safety (no switching off needed lights, DIM floor, safety lights stay on all night).
4. `GameStateService.setFixtureState` writes attributes, updates the world lights, and
   recomputes the zone with `DarknessMath.summarizeZone` (one 0–100 score).
5. Clients react to the score attribute: meter, sky (stars, haze, tint, bloom), fireflies.
6. `QuestService` restores the realm when score ≥ `restoreThreshold` **and** safe paths are lit,
   then runs the Moon tip vote.

## Remotes (all validated server-side)
| Remote | Direction | Payload | Server checks |
|---|---|---|---|
| ClientReady | C→S | – | starts quest once |
| FixtureAction | C→S | fixtureId, verb, option (strings ≤ 40 chars) | listed above |
| MoonVote | C→S | "agree" \| "doubt" | phase is MoonTip, value in set |
| RequestTestReset | C→S | – | `FeatureFlags.EnableTestReset` and `RunService:IsStudio()` |
| OpenFixtureMenu, Notice, Dialogue, GlareEvent, ShowCompare | S→C | ids/keys only | – |

Clients receive text **keys**, not text, so localization stays on the client.

## Scoring (DarknessMath)
Per fixture: glare, uplight (sky glow), over-lighting (above recommended brightness), and blue
light, each 0–1, weighted by `Tuning.Score.Weights` and scaled by the schedule's on-fraction.
Zone score = `100 × (1 − averageHarm × HarmScale)`. Safety is a constraint enforced by
`FixtureRules`, so turning lights off can never be the winning move.

Balance (CLI): start **30**, every light shielded **60**, every light shielded + aimed down +
dimmed to recommended + 3000K **97**. Restore threshold **75**.

## Persistence and analytics
None in M1: state resets per server. No personal data is stored or sent.
