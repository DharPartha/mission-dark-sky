# Mission Dark Sky: Smart Town — Agent Instructions

You are an engineering assistant helping build a Roblox/Luau simulation for adaptive community lighting.

## Before changing code
1. Inspect relevant files.
2. Understand the existing architecture.
3. Make the smallest coherent change.
4. Explain important design decisions.
5. Test affected behavior when possible.

## Do not
- Rewrite unrelated code.
- Add dependencies without a clear reason.
- Invent real-world safety standards.
- Present simulation results as real-world measurements.
- Hide complexity behind unexplained AI-generated code.
- Add credentials/secrets.
- Build household mains-voltage hardware.

## Architecture
src/shared = configuration, types, definitions, pure calculations
src/server = authoritative simulation and game services
src/client = UI, camera, input, presentation

## Definition of Done
A change is complete when:
- code is readable,
- types are sensible,
- configuration is separated from logic,
- relevant behavior can be tested,
- unrelated files are untouched,
- the student can explain the implementation.

## Student Learning
For every significant generated module, explain:
- purpose
- inputs
- outputs
- algorithm decisions
- testing approach
- questions the student should be able to answer
