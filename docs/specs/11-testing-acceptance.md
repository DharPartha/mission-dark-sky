# Testing and Acceptance Criteria

## Core Tests

### Test 1 — Empty
People = 0, vehicles = 0, event = false.
Result: target remains near configured baseline/safety behavior.

### Test 2 — Pedestrian
Increase people above zero.
Result: target lighting increases.

### Test 3 — Vehicle
Increase vehicles above zero.
Result: target lighting responds.

### Test 4 — Event
Set eventActive = true.
Result: target lighting increases according to configuration.

### Test 5 — Exit
Return activity to zero.
Result: lighting gradually decreases.

### Test 6 — Sunrise
Increase ambient light.
Result: artificial lighting demand decreases.

### Test 7 — Bounds
Use extreme inputs.
Result: target remains within configured minimum and maximum.

### Test 8 — Repeatability
Run the same scenario multiple times.
Result: deterministic inputs produce consistent decisions.

## Acceptance
The MVP is complete when:
- the parking lot loads,
- four lights are controllable,
- simulated inputs can change,
- the adaptive engine produces decisions,
- lights visibly respond,
- transitions are gradual,
- metrics update,
- required scenarios can be demonstrated,
- the student can explain the architecture and algorithm.
