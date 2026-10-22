# Mission Dark Sky: Smart Town — Agent Rules

Roblox/Luau simulation of adaptive community lighting.
Loop: SensorService → OptimizationService → LightingService → ImpactService → UI.

## Read only what the task needs
| Task | Read |
|---|---|
| Lighting logic | `src/shared/LightingMath.luau`, `Config.luau`, `src/server/OptimizationService.luau`, `docs/specs/05-*` |
| Sensors / scenarios | `SensorService`, `ScenarioService`, `src/shared/ScenarioDefinitions.luau`, `docs/specs/04-*`, `07-*` |
| Impact metrics | `ImpactService`, `docs/specs/06-*` |
| World / fixtures | `ParkingLotBuilder`, `LightingService`, `ActivityVisualizer`, `ZoneDefinitions`, `docs/specs/03-*` |
| UI | `src/client/UIController.client.luau`, `docs/specs/08-*` |
| Wiring / remotes | `src/server/Bootstrap.server.luau` |
| Architecture | `docs/architecture/system-architecture.md` |
| Physical prototype | `docs/physical-prototype/` (hardware tasks only) |

Skip: `roblox/*.rbxl` (binary place files), `*.svg` unless editing the diagram, `.DS_Store`.

## Layout (Rojo: `default.project.json`)
- `src/shared` → ReplicatedStorage: config, types, definitions, pure calculations.
- `src/server` → ServerScriptService: authoritative simulation. `Bootstrap.server` wires services and Remotes.
- `src/client` → StarterPlayerScripts: UI, camera, input, presentation only.
- Tests: `src/server/AcceptanceTests.luau` (runs in Studio), cases in `tests/README.md`.

## Rules
- Inspect relevant files first; make the smallest coherent change; don't touch unrelated code.
- Tunables go in `Config.luau`; keep logic out of UI scripts; keep inputs deterministic.
- The safety minimum is a constraint, not a score. Don't assume lights-off is better.
- Values are simulation parameters. Never invent real-world standards, measurements, or savings.
- No new dependencies, backends, or cloud services without a clear reason. No secrets.
- Physical prototype: low-voltage USB/battery only. Never mains voltage.
- Use Luau types and descriptive names; comment why, not what.
- Follow the phase order in `docs/specs/12-*`; don't expand the town before the core loop works.

## Done when
The code is readable and typed, config is separate from logic, behavior is testable in Studio,
unrelated files are untouched, the docs match the behavior, and the student can explain it.

## Explaining work (student project)
For each significant new module, briefly give its purpose, inputs, outputs, key algorithm choices,
and how to test it, plus 2–3 questions the student should be able to answer.
