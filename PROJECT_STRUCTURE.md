# Project Structure

```text
mission-dark-sky-smart-town/
├── .cursor/
│   └── rules/
│       └── mission-dark-sky.mdc
├── src/
│   ├── shared/
│   │   ├── Config.luau
│   │   ├── Types.luau
│   │   ├── LightingMath.luau
│   │   ├── ZoneDefinitions.luau
│   │   └── ScenarioDefinitions.luau
│   ├── server/
│   │   ├── MissionService.luau
│   │   ├── SensorService.luau
│   │   ├── OptimizationService.luau
│   │   ├── LightingService.luau
│   │   ├── ImpactService.luau
│   │   └── ScenarioService.luau
│   └── client/
│       ├── UIController.luau
│       ├── InteractionController.luau
│       └── CameraController.luau
├── assets/
├── docs/
├── tests/
├── default.project.json
├── AGENTS.md
└── README.md
```

### Boundaries
- shared: types, configuration, definitions, pure calculations
- server: authoritative simulation and calculations
- client: UI, camera, input, presentation

### Initial build
Start with Config, Types, LightingMath, SensorService, LightingService, and OptimizationService.
Add the remaining modules only when needed.
