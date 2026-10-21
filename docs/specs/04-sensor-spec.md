# Sensor Simulation Specification

## Purpose
Represent the kinds of information a real adaptive lighting system could use.

## Inputs

### People
Range: 0–20
Represents detected activity in the zone.

### Vehicles
Range: 0–20
Represents detected vehicle activity.

### Ambient Light
Range: 0–1
0 = dark simulation condition
1 = bright simulation condition

### Time
Range: 0–24
Represents simulated time of day.

### Weather
Initial values:
- Clear
- Rain
- Cloudy

### Event
Boolean indicating whether a configured event is active.

### Environmental Sensitivity
Range: 0–1
Represents how strongly environmental considerations influence the simulation.

## Important
These are simulated inputs. They are not claims that Roblox values are equivalent to physical
sensor measurements.

## Future Physical Mapping
Possible future low-voltage prototype inputs:
- PIR motion sensor
- ambient-light sensor
- optional temperature/humidity sensor

No household mains wiring is part of this project.
