# Acceptance Checklist (spec §14)

Status: **Pass (CLI)** = proven by automated command-line tests; **Implemented** = code exists and was
reviewed, but not yet Studio-tested; **Not tested** = needs a Studio, device, or published-experience
run; **Owner** = needs an owner action. Nothing here is marked as passing in Studio.

| # | Criterion | Status | Evidence / how to verify |
|---|---|---|---|
| 1 | New player enters Byers Station, understands the premise, uses Lux Lens and Star Journal, reaches Glarelands | Implemented | Act I mission; playthrough steps 1–10 |
| 2 | All four realms can be unlocked, investigated, completed, restored | Implemented; balance Pass (CLI) | Missions leo/orion/scorpius/cetus; per-zone tests; playthrough 11–15 |
| 3 | Moon reveal and all five final-boss phases work, then the complete ending | Implemented; phase solvability Pass (CLI) | Finale mission; "Finale phases are solvable" test; playthrough 17–24 |
| 4 | Solo players can finish all required content | Implemented; Pass (CLI) for step design | "Every mission step is completable solo" test; solo-gentler boss timing test |
| 5 | Co-op progression, scaling, disconnects, late joins predictable; personal progress not corrupted | Implemented | Party rules test, merge test; co-op playthrough |
| 6 | Puzzles reward useful, targeted, limited, controlled lighting while preserving safety lighting | Pass (CLI) | Per-zone tests; safety refusal tests |
| 7 | Darkness Meter reacts to solution quality and is not maximized by switching everything off | Pass (CLI) | "switching lights off alone restored the zone" assertion in every zone |
| 8 | Simulated readings and optional real-world observations clearly separated | Pass (CLI) + browser-checked | Report labels; site prints real-world notes under their own heading |
| 9 | Star Journal retains discoveries and offers export instructions after the ending | Implemented | Journal "Community report" button; report screen instructions |
| 10 | Proposal includes evidence, alternatives, trade-offs, recommendation, next steps | Pass (CLI) | Report section-order test; site parser test on the game's own output |
| 11 | Companion website: static, local PDF, copyable fallback, no account or upload | Pass (CLI) + browser-checked; deploy Owner | 11 site tests (no network, no HTML injection); Pages workflow |
| 12 | Persistent progress works in the intended setup; save failures do not reset valid saves | Pass (CLI) with a fake store; live Not tested | Save tests incl. outage, corrupt backup, newer version, locks, recovery merge |
| 13 | Only authorized developers use test resets; production data can't be reset accidentally | Implemented | `Environment` (fails closed), `DevService` checks; Stage B test B2 |
| 14 | Core UI and controls on mobile, PC, gamepad; accessibility options verified | Implemented; Not tested | Stage G checklist 7–9; settings saved per player |
| 15 | Documented end-to-end test performed; report separates verified from unverified | Script ready; test Not run | `docs/playthrough.md`; `docs/delivery-report.md` |

## Spec rules also checked
| Rule | Status |
|---|---|
| No graphic death; Glare is temporary and recoverable | Implemented (GlareService: slow + soft fade, High-five) |
| ≤ 3 flashes per second, no full-screen red flash | Implemented (one soft flash per attack; warm white washout) |
| Pledge never asks children to climb, unscrew, rewire, or touch fixtures | Pass (CLI): validator rejects such wording |
| No names, free text, addresses, or identifiers stored or sent | Implemented: saves hold flags, counts, ids; analytics allow-list |
| No ads, loot boxes, paid passes | Implemented (none exist) |
| Remotes validated and rate-limited | Implemented; rate limiter and pledge/quiz/settings validation Pass (CLI) |
