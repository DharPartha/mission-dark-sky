# Mission Dark Sky: Smart Town

**Tagline:** Make Every Light Count

Note: "Mission Dark Sky" has been renamed to "Vanishing Stars" for the Roblox game and Congressional App Challenge (CAC 2026) submission. This is a branding update only; the underlying project remains the same.

A Roblox engineering simulation exploring whether inexpensive sensors and adaptive algorithms
can make existing community lighting smarter.

## Core Question
Can communities provide the right amount of outdoor lighting at the right time while reducing
unnecessary energy use, cost, and environmental impact?

## Core Loop
Sensors & Conditions -> Adaptive Lighting Engine -> Lighting Adjustment -> Measure Impact -> Adapt

## First Milestone
Build ONE parking-lot lighting zone with:
- simulated people
- simulated vehicles
- time
- ambient light
- lighting-demand calculation
- gradual lighting adjustment
- basic impact metrics

Do not build the entire town first.

## Technology
Roblox Studio, Luau, Cursor, Git/GitHub, Rojo or Roblox Script Sync.
Optional: Roblox Studio MCP, Claude Code, later ESP32 + low-voltage sensors/LED.

Simulation values are demonstration parameters, not real-world lighting standards.

## Current MVP

Phases 1–6 are implemented for one parking-lot zone:

- four server-controlled fixtures with gradual transitions
- simulated people, vehicles, ambient light, time, weather, and event inputs
- adaptive target calculation with a nighttime safety floor
- estimated energy/cost and fixed/timed comparisons
- eight repeatable scenarios plus an automatic demo
- an in-game control and status panel

With Rojo connected, press **Play** in Roblox Studio. Use the panel on the right to select a
scenario or change inputs. Values labeled "Estimated" are simulation estimates, not electrical
measurements or real-world lighting standards.
