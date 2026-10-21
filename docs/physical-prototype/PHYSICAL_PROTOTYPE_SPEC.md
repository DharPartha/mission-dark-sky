You are helping build the physical proof-of-concept for:

MISSION DARK SKY: SMART TOWN
Tagline: Make Every Light Count

PROJECT GOAL

Build a small, safe, low-voltage physical prototype demonstrating the adaptive lighting concept from the Roblox Smart Town simulation.

The prototype should demonstrate:

Night + empty area
→ low lighting

Motion detected
→ lighting gradually increases

More activity
→ lighting increases further

No activity
→ lighting gradually returns to the lower level

Daylight
→ lighting turns off or remains at minimum

The goal is NOT to build a real outdoor lighting product.
The goal is to create a small engineering proof-of-concept showing how inexpensive sensors and an adaptive algorithm can make an existing light respond to actual conditions.

IMPORTANT SAFETY CONSTRAINT

Use ONLY low-voltage USB/battery-powered electronics.

DO NOT design or provide instructions for:
- household/mains AC wiring
- wall outlets
- mains-powered floodlights
- high-voltage electrical work
- dangerous electrical modifications

The prototype should use a low-voltage LED module or LED strip.

--------------------------------------------------
HARDWARE TARGET
--------------------------------------------------

Recommended components:

1. ESP32 development board
2. PIR motion sensor
3. BH1750 ambient-light sensor
4. Low-voltage LED module or LED strip
5. Breadboard
6. Jumper wires
7. USB power supply
8. Optional small OLED display

Optional future components:
- temperature/humidity sensor
- small solar panel
- battery
- additional LED/light zones

Do not require optional components for the MVP.

--------------------------------------------------
MVP HARDWARE ARCHITECTURE
--------------------------------------------------

Create this architecture:

PIR Motion Sensor
        |
        v
      ESP32 <---- BH1750 Ambient Light Sensor
        |
        v
   Adaptive Lighting Engine
        |
        v
   PWM LED Brightness

Optional:

ESP32
  |
  v
OLED Display

The ESP32 is the controller.

--------------------------------------------------
SENSOR INPUTS
--------------------------------------------------

The MVP should use:

motionDetected: boolean

ambientLight: numeric value from BH1750

timeOfDay: simulated initially

activityLevel: derived from motion initially

The physical prototype should NOT require a real-time clock for the first version.

For the MVP, provide a simple configuration option allowing the developer to simulate:

DAY
NIGHT

This makes testing easy.

--------------------------------------------------
ADAPTIVE LIGHTING LOGIC
--------------------------------------------------

Do NOT implement this as simple:

motion = ON
no motion = OFF

The central concept is:

"What amount of lighting is needed right now?"

Use configurable simulation parameters.

Example:

Night + empty:
25%

Night + motion:
70%

Continued activity:
80–90%

No motion for timeout period:
gradually return to 25%

Day:
0–10%

These values are demonstration parameters only.

Do NOT describe them as real-world safety standards.

The algorithm should support:

minimumBrightness
maximumBrightness
motionBrightness
idleBrightness
daylightThreshold
motionTimeout
rampUpRate
rampDownRate

All values should be configurable.

--------------------------------------------------
GRADUAL LIGHTING
--------------------------------------------------

Do NOT immediately jump:

25% → 70%

Instead transition gradually:

25%
30%
35%
40%
...
70%

Likewise when motion stops:

70%
65%
60%
55%
...
25%

Implement a configurable ramp rate.

--------------------------------------------------
AMBIENT LIGHT BEHAVIOR
--------------------------------------------------

Use the BH1750 to determine whether the environment is sufficiently bright.

Conceptually:

if ambientLight > daylightThreshold:
    targetBrightness = 0

else:
    calculate adaptive nighttime brightness

The threshold must be configurable.

Do not claim the threshold represents a real municipal lighting standard.

--------------------------------------------------
MOTION BEHAVIOR
--------------------------------------------------

When PIR detects motion:

targetBrightness = motionBrightness

When motion stops:

start the configurable timeout.

After timeout:

targetBrightness = idleBrightness

The light should transition gradually.

Avoid rapid oscillation caused by repeated PIR triggers.

--------------------------------------------------
SOFTWARE ARCHITECTURE
--------------------------------------------------

Organize the firmware into logical modules.

Suggested structure:

physical-prototype/
│
├── README.md
├── docs/
│   ├── hardware-spec.md
│   ├── adaptive-lighting-spec.md
│   ├── wiring-spec.md
│   ├── testing-plan.md
│   └── safety.md
│
├── firmware/
│   ├── main/
│   ├── sensors/
│   │   ├── PIRSensor
│   │   └── BH1750Sensor
│   ├── lighting/
│   │   └── AdaptiveLightingEngine
│   ├── config/
│   │   └── Config
│   └── display/
│       └── OLEDDisplay
│
└── tests/

If a simpler structure is more appropriate for the selected ESP32 framework, explain the change before implementing it.

--------------------------------------------------
ADAPTIVE LIGHTING ENGINE
--------------------------------------------------

Create a clean function/interface similar to:

calculateTargetBrightness(
    ambientLight,
    motionDetected,
    activityLevel,
    dayNightState
)

Return:

targetBrightness

The engine should be independent from the physical sensor code.

This is important because the same conceptual engine will later be represented in the Roblox Smart Town simulation.

--------------------------------------------------
STATE MODEL
--------------------------------------------------

Use clear states such as:

DAY
NIGHT_IDLE
NIGHT_ACTIVE
NIGHT_COOLDOWN

Possible behavior:

DAY
→ minimum/off

NIGHT_IDLE
→ low brightness

NIGHT_ACTIVE
→ higher brightness

NIGHT_COOLDOWN
→ gradual reduction

Do not make the state machine unnecessarily complex.

--------------------------------------------------
OPTIONAL OLED DISPLAY
--------------------------------------------------

If an OLED is included, display:

MISSION DARK SKY

Ambient: ___ lux
Motion: YES/NO
State: NIGHT_ACTIVE
Light: ___ %

The display should help someone watching the demonstration understand what the system is doing.

--------------------------------------------------
SERIAL MONITOR
--------------------------------------------------

Even if OLED is not implemented initially, provide useful serial output.

Example:

[08:32:10]
Ambient: 12 lux
Motion: YES
State: NIGHT_ACTIVE
Target: 70%
Current: 55%

Then:

[08:32:15]
Ambient: 12 lux
Motion: NO
State: NIGHT_COOLDOWN
Target: 25%
Current: 62%

This will make debugging and demonstration easier.

--------------------------------------------------
TEST MODES
--------------------------------------------------

Create a development/test mode that allows simulation without physically triggering sensors.

The developer should be able to test:

1. DAY
2. NIGHT + EMPTY
3. NIGHT + MOTION
4. NIGHT + MOTION ENDS
5. NIGHT + REPEATED MOTION
6. DAYLIGHT WHILE LIGHT IS ACTIVE
7. SENSOR FAILURE / INVALID READING

Do not allow a failed sensor reading to create unpredictable behavior.

Define a safe fallback behavior appropriate for this low-voltage demonstration.

--------------------------------------------------
MEASUREMENTS
--------------------------------------------------

Track:

- ambient light
- motion state
- current brightness
- target brightness
- state
- time in active state
- estimated energy use

If energy consumption is estimated rather than measured, clearly label it:

"Estimated Energy"

Do not present estimates as measured electrical results.

--------------------------------------------------
DEMO SCENARIO
--------------------------------------------------

The final demonstration should be approximately:

1. Room/environment is dark.
2. LED starts at 25%.
3. Nobody is present.
4. Person approaches.
5. PIR detects motion.
6. LED gradually increases to approximately 70%.
7. Person leaves.
8. Timeout begins.
9. LED gradually returns to 25%.
10. Ambient light increases.
11. System detects daylight.
12. LED turns off or reaches minimum.

The entire sequence should be easy to repeat.

--------------------------------------------------
ROBLOX CONNECTION
--------------------------------------------------

This physical prototype is a proof-of-concept for:

Mission Dark Sky: Smart Town

The conceptual architecture should match:

Sensors & Conditions
        ↓
Adaptive Lighting Engine
        ↓
Lighting Adjustment
        ↓
Measure Impact
        ↓
Adapt

Roblox will simulate the larger Smart Town.

The physical prototype demonstrates that the adaptive-lighting concept can also respond to real sensor inputs.

Do NOT build an internet/cloud connection between Roblox and ESP32 yet.

Do NOT add AWS, databases, IoT cloud platforms, APIs, or unnecessary networking.

Keep the MVP local and understandable.

--------------------------------------------------
SOLAR
--------------------------------------------------

Solar power is a future/optional extension.

Do not make solar power a dependency for the first prototype.

If documenting the future architecture, describe:

Solar panel
→ charge controller
→ battery
→ low-voltage electronics

Do not provide mains wiring instructions.

--------------------------------------------------
COST / COMMUNITY STORY
--------------------------------------------------

The prototype should support the larger question:

"Can inexpensive sensors and adaptive algorithms make existing community lighting smarter—providing the right amount of light when people need it while reducing unnecessary energy use, cost, and environmental impact?"

Do not assume adaptive lighting is automatically better.

The system should eventually allow comparison between:

1. Fixed lighting
2. Timed lighting
3. Motion-based lighting
4. Adaptive lighting
5. Optional solar + adaptive lighting

The physical MVP only needs to demonstrate adaptive behavior.

--------------------------------------------------
IMPLEMENTATION PROCESS
--------------------------------------------------

IMPORTANT:

Do NOT immediately generate the entire project.

First:

1. Analyze this specification.
2. Identify the recommended ESP32 development framework.
3. Identify required libraries.
4. Identify exact hardware interfaces.
5. Produce a hardware bill of materials.
6. Produce a safe wiring plan.
7. Produce firmware architecture.
8. Produce the adaptive-lighting state machine.
9. Produce a testing plan.
10. Identify anything ambiguous or missing.

Then STOP and wait for approval.

After approval, implement one milestone at a time.

Milestone 1:
ESP32 + LED basic PWM control.

Milestone 2:
BH1750 integration.

Milestone 3:
PIR integration.

Milestone 4:
Adaptive Lighting Engine.

Milestone 5:
Gradual transitions and cooldown.

Milestone 6:
Serial monitoring.

Milestone 7:
Optional OLED.

Milestone 8:
Final demonstration mode.

After each milestone explain:

- What was implemented
- Files changed
- Hardware required
- How to test
- Expected result
- Known limitations

--------------------------------------------------
STUDENT UNDERSTANDING
--------------------------------------------------

This is a student competition project.

Do not hide complexity behind unexplained libraries or generated code.

Prefer simple, readable code.

The student should be able to explain:

- What the PIR sensor does
- What BH1750 measures
- What PWM does
- How the adaptive algorithm works
- Why brightness changes gradually
- Why ambient light matters
- How the physical prototype relates to Roblox
- What is simulated versus actually measured
- What limitations the prototype has

AI may assist development, but the final implementation must remain understandable to the student.

--------------------------------------------------
FINAL OUTPUT OF THIS PLANNING STEP
--------------------------------------------------

Before writing any firmware, provide:

A. Recommended hardware list
B. Exact ESP32 board recommendation
C. Sensor recommendations
D. LED recommendation
E. Safe low-voltage architecture
F. Pin/interface plan
G. Software/framework recommendation
H. Required libraries
I. Project folder structure
J. Adaptive-lighting algorithm
K. State machine
L. Testing plan
M. Demonstration plan
N. Estimated prototype complexity
O. What should NOT be built yet
P. Questions/decisions requiring approval

DO NOT WRITE THE FINAL FIRMWARE YET.

Wait for approval after presenting the implementation plan.
