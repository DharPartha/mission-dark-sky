# Architecture

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
 Adaptive Lighting Engine
          |
          v
   LightingService
       /             v         v
Roblox Lights  ImpactService
                  |
                  v
               UI/Metrics
```

The server owns authoritative simulation decisions. The client visualizes and interacts with
the simulation.

The system should answer: given changing community conditions, how should lighting adapt?
