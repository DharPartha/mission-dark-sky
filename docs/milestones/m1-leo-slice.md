# Milestone 1 — Leo Vertical Slice

**Success condition (spec §18):** a player inspects an over-bright or poorly aimed fixture, sees
evidence, makes a safe adjustment, observes a meaningful before/after change, and restores Leo's
realm. No safety-critical light may be switched off.

## Scope
Built: Lantern Lane test area, three fixtures, Inspect + verb menu, server validation, Lux Lens,
Darkness Meter → sky/fireflies, Leo state machine with roar/Glare, one Moon tip vote, NPC friends,
comic bubbles, config validator, self tests, accessibility toggles, Studio reset.

Not in M1: Glarelands mirror world and Rift (Leo looms over Byers Station instead), bikes, audio,
persistence, Star Journal UI (entries are recorded server-side), pledge, Spanish, quality tiers,
teammate high-five recovery, co-op preset phrases (the vote is the only co-op choice).

## Studio test steps

### Setup
1. `rojo build -o roblox/the-dark-sky.rbxl`, open the file in Studio (or `rojo serve` + Connect).
2. Open **View → Output**. Press **Play**.

**Expected in Output:** `Config check: 0 errors, 0 warnings`, `Self tests: 16 passed, 0 failed`,
`Lantern Lane ready: 3 fixtures`. No red errors.

### Solo flow
| # | Do | Expected |
|---|---|---|
| 1 | Wait at spawn | Narration and four friend/Moon bubbles play (~30 s). Objective: "Listen to your friends." then "Walk to a streetlight and inspect it." Meter shows about 30 / 100, Hazy |
| 2 | Press F / tap Talk on a friend | That friend speaks a hint over their head |
| 3 | Walk east to the corner streetlight, press E / tap Inspect | Fixture menu opens with readings; notice "New evidence: Lux Lens glare reading"; Leo wakes (narration + "ROAR!" shout); objective "Fix the glare. Reach 75…" |
| 4 | Tap **Lux Lens** | Reading tags over all 3 lights; red glare circles on the ground |
| 5 | Wait ~14 s standing inside a red circle | Yellow warning banner for 3 s, then washout + slow walk for 4 s; no damage |
| 6 | Repeat while standing outside all circles | Banner only, no Glare |
| 7 | Corner light: Add shield, Aim lower ×1 (a 2nd press is refused), Dimmer ×5, Warmer ×2 | Each press: notice + light visibly changes; meter rises; glare circle shrinks/vanishes |
| 8 | Crosswalk light: Is it needed? | "Required: walkers cross here…" ; evidence "Crossing light is needed" |
| 9 | Crosswalk light: Turn off | Refused: "Safety light! It must stay on." Light stays on |
| 10 | Crosswalk light: Dimmer until refused | Stops at 60%: "Safety light: it can't go dimmer than this." |
| 11 | Crosswalk light: Change timer | Refused: "must stay on all night" |
| 12 | Undo on any light | Last change reverts |
| 13 | Fix garage flood + crosswalk (shield, aim down, dim, warm) | Score passes 75 → "Leo's realm restored!", Before/After panel opens, Leo turns pale blue, eyes fade, stars appear, fireflies in the meadow, Leo hints someone fed him glare |
| 14 | Moon tip panel appears | Tip "switch EVERY light off", evidence list, 30 s countdown, brief red glint in the Moon's eye |
| 15 | Tap **Doubt it!** | "Doubt Token earned!", Moon backpedals, Adrika explains; objective "Leo's realm restored! Doubt Tokens: 1" |
| 16 | Settings → Reset realm (Studio test) | Lights polluted again, Leo red, objective back to inspect |
| 17 | Redo and pick **Sounds right** | "No Doubt Token this time." Adrika corrects; slice still completes |

### Two-player (Test tab → Clients and Servers → 2 players)
- Both clients see the same light changes, meter, Leo state, and evidence notices.
- Only the acting player gets action notices; the menu only opens for whoever inspected.
- Moon vote waits for both or 30 s. 1–1 tie → Moon "I'll take that as a yes!", no token.
- Player 2 too far from a light (open menu, walk away): menu closes; a forced request gets "Move closer".

### Accessibility and mobile
- Settings: Reduced motion (text appears instantly, no fireflies, meter snaps), Large text, High contrast.
- Studio **Device emulator** (phone landscape): all buttons tappable, panels fit, prompts tappable.

## Results log
Record each run: date, commit, platform/device, players, pass/fail per step, notes.

| Date | Commit | Platform | Players | Result | Notes |
|---|---|---|---|---|---|
| 2026-10-22 | (uncommitted) | macOS CLI (Luau) | – | Self tests 16/16 pass; Rojo build OK | Studio playtest not yet run |

## Known limitations / risks to check in Studio
- Atmosphere and bloom values are untested visually; Leo and the Moon are ~300 studs away and may
  look too hazy or too bright. Tune `Tuning.Sky` and `BossConfig.Leo.panelCenter`.
- The intro waits for the server's time estimate even if players tap through bubbles faster.
- Prompt labels use the default locale (server-built); HUD and dialogue follow the player locale.
- NPCs use default avatars from `CreateHumanoidModelFromDescription`; if it fails they become block figures.
- No measured FPS yet. Not tested on a phone, Windows laptop, or gamepad.

## Explaining the new modules (student notes)
**DarknessMath** turns fixture settings into readings and one 0–100 score.
Inputs: fixture definition + state. Outputs: readings, zone score, glare zones. Choice: weighted
harm with safety kept separate as a rule. Test: `python3 scripts/run_self_tests.py`.
- Why is safety a rule in FixtureRules instead of a score penalty?
- Which verb lowers the score the most for the garage flood, and why?

**FixtureRules / FixturePuzzleService** apply verbs safely. Inputs: player request. Output: new
state or a refusal notice. Choice: shared pure rules + server-only network checks.
- What would a cheating client gain by sending `QUESTION off` for the crosswalk? Why nothing?
- Why does the server check distance even though the prompt already has a range?

**QuestService** is a state machine (Intro → Investigate → Confront → Restored → MoonTip → Complete).
- What happens if a team fixes every light before inspecting anything?
- Why can a team still win with zero Doubt Tokens?
