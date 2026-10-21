# Smart Parking Lot Specification

## Purpose
Provide the first complete demonstration of adaptive lighting.

## Environment
- Parking spaces
- A road/driveway
- Four controllable light fixtures
- A pedestrian area
- Vehicle activity area
- Sensor/zone visualization for debugging

## Fixtures
Each fixture must support:
- enabled/disabled state
- current brightness
- target brightness
- gradual transition

## Initial Scenarios
### Empty
People = 0
Vehicles = 0
Event = false
Expected: low baseline lighting.

### Pedestrian
People > 0
Expected: lighting increases gradually.

### Vehicle Activity
Vehicles > 0
Expected: lighting increases according to configured demand.

### Multiple Activity
People and vehicles increase.
Expected: higher target level.

### Event
Event = true
Expected: higher lighting demand.

### Exit
Activity returns to zero.
Expected: lighting gradually returns toward baseline.

### Sunrise
Ambient light becomes high.
Expected: artificial lighting demand decreases.

These are simulation scenarios, not real-world lighting requirements.
