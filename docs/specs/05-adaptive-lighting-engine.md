# Adaptive Lighting Engine Specification

## Purpose
Determine the simulated lighting level required by a zone based on current conditions.

## Inputs
- people: 0–20
- vehicles: 0–20
- ambientLight: 0–1
- timeOfDay: 0–24
- weather
- eventActive: true/false
- environmentalSensitivity: 0–1

## Output
targetLightingLevel: 0–1

## Conceptual Model
Lighting Need =
Safety Requirement
+ Activity Demand
+ Event Demand
+ Visibility Adjustment
- Ambient Contribution
- Environmental Reduction

## Constraints
- Minimum and maximum values must be configurable.
- Output must always remain within configured bounds.
- Safety minimum is treated as a constraint rather than merely a score.

## Transition
Lighting should not instantly jump between target values.

Example:
25% -> 60%

should transition gradually.

## Design Principles
- Do not assume all lighting should be turned off.
- Do not assume adaptive lighting is always superior.
- The system should make its decision inputs visible.
- Configuration values must be separate from calculation logic.

## Parameter Warning
Prototype coefficients and thresholds are simulation parameters only. They are not
real-world lighting standards or engineering recommendations.
