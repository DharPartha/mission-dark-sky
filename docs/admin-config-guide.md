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
| Leo's shape, colors, roar timing | `BossConfig` | `telegraphSeconds` must be shorter than `roarIntervalSeconds` |
| Bubble colors and speed | `BubbleTheme` | |
| Story order and steps | `MissionConfig` | Step kinds: dialogue, inspect, restore, moonTip |
| Analytics events | `AnalyticsConfig` | Names only, snake_case, no personal data |
| Rate limits | `Tuning.Remotes` | Burst and per-second per player |
| Dev place, dev users, save timing | `src/server/ServerConfig/DevConfig.luau` | Server-only; never put production PlaceIds in `DevPlaceIds` |
| Turn systems on/off | `FeatureFlags` | Test tools also need a dev environment and authorized user |

Asset ids (when audio/art configs are added) must be `""` (placeholder) or `rbxassetid://<number>`.

Before release, the owner must review every dialogue line, Moon tip, and any real-world fact card.
