# Mission Dark Sky: Smart Town — System Architecture

## Overview

This diagram shows the high-level service architecture and data flow for the adaptive community lighting simulation.

![Mission Dark Sky system architecture with Roblox, Luau, and Rojo icons](./system-architecture.svg)

### Icon key

The diagram uses platform icons for the tools this project actually runs on (Roblox server and
client, Luau, Rojo, Roblox Studio). Every other component uses a colour-coded category tile in the
style of cloud architecture diagrams:

| Colour | Category | Components |
|---|---|---|
| Orange | Build / compute | ParkingLotBuilder |
| Red | Game loop | Bootstrap (`RunService.Heartbeat`) |
| Green | IoT / sensing | SensorService, ZoneDefinitions, physical prototype |
| Teal | Decision logic | OptimizationService, LightingMath |
| Purple | Analytics / networking | ImpactService, Remotes |
| Pink | Configuration | Config, ScenarioService, ScenarioDefinitions |

No cloud services (AWS or otherwise) are part of this system. The physical prototype spec
deliberately excludes them, so the diagram shows no cloud service logos.

The icons are drawn inline in the SVG with no external assets. To change the diagram, edit
`system-architecture.svg` directly.

### Text version (Mermaid)

```mermaid
graph TB
    subgraph Input["🔷 Input Layer"]
        Sensors["Sensors<br/>(Motion, Occupancy, Sky Quality)"]
        Scenarios["Scenarios<br/>(Time, Weather, Events)"]
    end

    subgraph Server["🔴 Server (Authoritative)"]
        SensorSvc["SensorService<br/>Simulates sensor data"]
        OptSvc["OptimizationService<br/>Calculates optimal lighting"]
        LightingSvc["LightingService<br/>Applies lighting decisions"]
        ImpactSvc["ImpactService<br/>Measures outcomes"]
    end

    subgraph Shared["🟡 Shared (Client + Server)"]
        Config["Config<br/>Parameters & settings"]
        Types["Types<br/>Data structures"]
        Math["LightingMath<br/>Pure calculations"]
        Defs["Definitions<br/>Zones & scenarios"]
    end

    subgraph Output["🟢 Output Layer"]
        RobloxLights["Roblox Lights<br/>Visual simulation"]
        Metrics["UI & Metrics<br/>Impact visualization"]
    end

    subgraph Client["🔵 Client (Presentation)"]
        UI["UIController<br/>User interface"]
        Camera["Camera & Rendering"]
    end

    Sensors --> SensorSvc
    Scenarios --> SensorSvc
    SensorSvc --> OptSvc
    OptSvc --> LightingSvc
    LightingSvc --> ImpactSvc
    
    Config -.-> SensorSvc
    Config -.-> OptSvc
    Config -.-> LightingSvc
    Config -.-> ImpactSvc
    
    Math -.-> OptSvc
    Math -.-> LightingSvc
    
    Defs -.-> SensorSvc
    Defs -.-> LightingSvc
    
    LightingSvc --> RobloxLights
    ImpactSvc --> Metrics
    
    RobloxLights --> Camera
    Metrics --> UI
    Camera --> UI
    UI --> Client

    style Input fill:#e1f5ff
    style Server fill:#ffcdd2
    style Shared fill:#fff9c4
    style Output fill:#c8e6c9
    style Client fill:#e0e7ff
```

## Data Flow

| Layer | Responsibility | Key Services |
|-------|---|---|
| **Input** | Sensor readings and scenario conditions | SensorService (simulation) |
| **Processing** | Adaptive optimization and control | OptimizationService, LightingService |
| **Analysis** | Measure impact and outcomes | ImpactService |
| **Shared** | Types, math, config used across all layers | Config, Types, LightingMath, Definitions |
| **Output** | Visual rendering and metrics | Roblox Lights, UI/Metrics |
| **Client** | User interface and camera control | UIController |

## Key Principles

- **Server Authoritative** — All simulation decisions are made on the server
- **Shared Calculations** — Pure math and definitions are in `src/shared` for testability
- **Configuration Driven** — Behavior is controlled via Config, not hardcoded
- **Clear Separation** — Client handles UI/presentation only, never simulation logic

## Directory Structure

```
src/
├── shared/           # Shared code (Config, Types, Math, Definitions)
├── server/           # Server services (simulation & business logic)
└── client/           # Client UI (presentation only)

docs/
└── architecture/     # This documentation
```
