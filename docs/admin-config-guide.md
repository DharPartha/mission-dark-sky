# Admin Configuration Guide

Everything players read, and most balance numbers, live in `src/shared/Config/`. You can change
them without touching gameplay scripts. After any edit, press **Play** in Studio and read the
Output line `Config check: N errors, N warnings`, or run `python3 scripts/run_self_tests.py`.
Errors name the file and the entry to fix.

| I want to change… | Edit | Notes |
|---|---|---|
| Title, version, languages | `ExperienceConfig` | Adding `"es"` to `SupportedLocales` makes the validator list every missing Spanish line |
| Any button, label, notice, objective | `UIText.Strings` | Keep `%d` / `%s` placeholders identical in every language |
| Dialogue lines, order, friend hints | `DialogueConfig` | Max 90 characters per line; styles: speech, shout, thought, narration |
| Moon tips and evidence | `MoonTipsConfig` | Each tip's `evidenceKey` must be findable before the tip plays |
| Lights in a zone | `FixtureConfig` | `Required` lights must use `allowedSchedules = { "AllNight" }` and a `minBrightness` above 0 |
| Restore target | `FixtureConfig.Zones.Leo.restoreThreshold` | Score 0–100 |
| Score weights, step sizes, glare, sky look | `Tuning` | All numbers are game estimates |
| Guardians: shape, colors, arena, attack | `BossConfig` | `attack.kind` = roar / sweep / strike; telegraph ≥ 1.5 s and shorter than the interval |
| Town lights that improve with each realm | `FixtureConfig.Echoes` | One list per zone |
| Moon clues for the reveal | `MoonTipsConfig.Clues` | Plain in-game observations |
| Boss fairness | `Tuning.Bosses` | Solo slowdown and extra warning time |
| Finale phases | `MissionConfig` (`finale` mission) | `required`, `tokenDiscountAt`; validator checks fixtures exist |
| Community report wording | `ReportConfig` | Fictional places only; owner review required |
| Companion website link | `ExperienceConfig.CompanionSiteUrl` | `""` until deployed, then the real `https://` Pages URL |
| Post-adventure check | `QuizConfig.Quizzes.post` | Same questions as the pre-check; `showAnswers` reveals answers afterwards |
| Night Sky Pledge actions | `PledgeConfig` | Validator rejects actions that ask players to climb, unscrew, rewire, or touch fixtures |
| Bubble colors and speed | `BubbleTheme` | |
| Story order and steps | `MissionConfig` | Step kinds: dialogue, quiz, interact, grant, inspect, restore, reach, moonTip, phase, claims, ending, pledge |
| Places, signs, friend stations, checkpoints | `WorldConfig` | Positions in studs; Glarelands = town + (4000, 0, 0) |
| Knowledge-check questions | `QuizConfig` | Preset choices only; `correct` is the choice number; owner review required |
| Bike speeds, hint timing | `Tuning.Bike`, `Tuning.Guidance` | |
| Analytics events | `AnalyticsConfig` | Names only, snake_case, no personal data |
| Rate limits | `Tuning.Remotes` | Burst and per-second per player |
| Dev place, dev users, save timing | `src/server/ServerConfig/DevConfig.luau` | Server-only; never put production PlaceIds in `DevPlaceIds` |
| Turn systems on/off | `FeatureFlags` | Test tools also need a dev environment and authorized user |

Asset ids (when audio/art configs are added) must be `""` (placeholder) or `rbxassetid://<number>`.

Before release, the owner must review every dialogue line, Moon tip, and any real-world fact card.
