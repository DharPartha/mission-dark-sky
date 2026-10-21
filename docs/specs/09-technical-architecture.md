# Technical Architecture

## Technology
- Roblox Studio
- Luau
- Cursor
- Git/GitHub
- Rojo or Roblox Script Sync
- Optional Roblox Studio MCP
- Optional Claude Code

## Architecture

```text
Scenario / Sensor Inputs
          |
          v
    SensorService
          |
          v
 OptimizationService
          |
          v
 Adaptive Lighting Engine
          |
          v
    LightingService
       /       \
      v         v
Roblox Lights  ImpactService
                  |
                  v
               UI/Metrics
```

## Responsibilities

### Shared
- types
- configuration
- definitions
- pure calculations

### Server
- authoritative simulation state
- sensor simulation
- adaptive calculations
- lighting decisions
- impact calculations
- scenario control

### Client
- UI
- camera
- user interaction
- presentation

## Initial Modules
- Config
- Types
- LightingMath
- SensorService
- OptimizationService
- LightingService

## Principles
- Keep calculations testable.
- Avoid duplicated logic.
- Keep configuration separate from code.
- Do not add a backend unless a real requirement appears.
