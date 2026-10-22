# Architecture

**See [System Architecture Diagram](./architecture/system-architecture.md)** for the full diagram (SVG with platform icons, plus a Mermaid text version).

## Quick Overview

```text
Sensor / Scenario Inputs
          |
          v
   SensorService
          |
          v
 OptimizationService
          |
          v
   LightingService
       /         \
Roblox Lights  ImpactService
                  |
                  v
               UI/Metrics
```

## Core Principle

The server owns authoritative simulation decisions. The client visualizes and interacts with
the simulation.

**The system should answer:** Given changing community conditions, how should lighting adapt?
