# The Dark Sky — Agent Rules

Roblox/Luau cooperative adventure about responsible lighting. Build contract:
`docs/specs/The_Dark_Sky_Claude_Game_Build_Spec.pdf` (owner-approved changes only).
Current milestone: **M1 Leo vertical slice** (see `docs/milestones/m1-leo-slice.md`).

Loop: Inspect (Lux Lens) → fixture verb → server validates → Darkness score → sky/HUD/Leo → Moon tip.

## Read only what the task needs
| Task | Read |
|---|---|
| Scoring / meter | `src/shared/Shared/DarknessMath.luau`, `Config/Tuning.luau` |
| Fixture verbs / safety | `Shared/FixtureRules.luau`, `Config/FixtureConfig.luau`, `server/Services/FixturePuzzleService.luau` |
| Quest / Leo / Moon tip | `server/Services/QuestService.luau`, `BossAIService.luau`, `Config/BossConfig.luau`, `Config/MoonTipsConfig.luau` |
| Dialogue / text | `Config/DialogueConfig.luau`, `Config/UIText.luau`, `Shared/Text.luau`, `client/Controllers/BubbleRenderer.luau` |
| World / art | `server/Services/WorldBuilder.luau` |
| UI | `src/client/Controllers/*` |
| Wiring / remotes | `src/server/Bootstrap.server.luau`, `Shared/Net.luau` |
| Config validation | `Shared/ConfigValidator.luau`, `docs/admin-config-guide.md` |
| Architecture | `docs/architecture.md` |

Skip: `roblox/*.rbxl` (old binary places), `*.pdf` unless the spec is needed, `.DS_Store`.

## Layout (Rojo: `default.project.json`)
- `src/shared/Config` → `ReplicatedStorage.DarkSky.Config`: all editable content and tuning.
- `src/shared/Shared` → `ReplicatedStorage.DarkSky.Shared`: types, pure logic, text lookup, remote names.
- `src/server` → `ServerScriptService.DarkSky`: authoritative services; `Tests/SelfTests`.
- `src/client` → `StarterPlayerScripts.DarkSky`: presentation and input only.

## Rules
- Inspect relevant files first; make the smallest coherent change; implement only the current milestone.
- All player-facing text comes from config (`UIText`, `DialogueConfig`, `MoonTipsConfig`), never script strings.
- Tunables go in `Config/`; keep logic out of UI scripts; the server validates every remote.
- Safety-critical lights (paths, doors, stairs, crossings) can be improved, never switched off. Never reward total darkness.
- Readings are game estimates. Never invent real-world standards, measurements, savings, or fact-card claims.
- No new dependencies, backends, ads, paid items, or personal data. No secrets.
- `--!strict` Luau, descriptive names, file headers; comment why, not what.
- Never claim a Studio test passed unless it was run there. CLI self tests: `python3 scripts/run_self_tests.py`.

## Done when
Readable typed code, config separate from logic, validator and self tests pass, behavior is testable in
Studio with the steps in the milestone doc, docs match behavior, and the student can explain it.

## Explaining work (student project)
For each significant new module, give its purpose, inputs, outputs, key algorithm choices,
and how to test it, plus 2–3 questions the student should be able to answer.
