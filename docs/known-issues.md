# Known Issues, Placeholders, and Manual Setup

## Not yet verified
- **No full Studio playthrough has been run for Stages B–H.** Only the Milestone 1 server start was
  seen in Studio (config check and self tests passed there). Everything else is code-reviewed and
  covered by command-line tests, not playtested. Use `docs/playthrough.md`.
- No FPS or memory measurements on any device (phone, integrated-graphics laptop, gamepad).
- Live DataStore behavior (outage, lock takeover, recovery merge) is tested only with a fake store.
- The browser print dialog of the companion site was not opened; the preview was checked in a browser.

## Placeholders (owner assets or review needed)
- All art is Roblox primitive parts: town, Glarelands, fixtures, bike, guardians (star figures in the
  sky), and the Moon (a glowing sphere with a star crown). No rigged meshes or animations.
- The splash screen is drawn from UI shapes (no image assets); the town-sky constellations are
  small glowing parts placed far above town, faint until their realm is restored.
- NPC friends are block figures built from parts (no avatar download), each with a soft warm light.
- No audio. Every important sound has a caption instead (Moon chime, bell, roars via banners).
- All dialogue, Moon tips, quiz questions, pledge actions, evidence, and report wording are
  placeholders for owner review (spec §8, §9). No real-world facts or measurements are claimed.
- English only (`SupportedLocales = { "en" }`); the validator lists missing lines when a locale is added.

## Studio debugger note
If Studio's debugger is set to break on **all** exceptions, it pauses on errors the game catches
on purpose. The server start skips the three fake-outage save tests for this reason (they still
run in `scripts/run_self_tests.py` and CI). To avoid pauses from other caught errors, set Studio's
exception breakpoints to unhandled errors only.

## Gameplay limitations
- The rider's legs play the walking animation on a bike (ride mode, not a physics bike).
- Water (pond, creek) is flat colored parts; players can walk on it.
- Glare penalties and attack markers are server-side; with high latency markers can lag slightly.
- Intro dialogue timing is estimated by the server; tapping through bubbles does not speed the story.
- ProximityPrompt labels are built on the server in the default language.
- Roblox can't write to the clipboard: players select and copy the report text themselves.

## Manual setup still required
1. Publish a private **dev** experience, enable Studio API access, fill `DevPlaceIds`/`DevUserIds`.
2. Enable GitHub Pages (Source: GitHub Actions); set `ExperienceConfig.CompanionSiteUrl`.
3. Owner content review (above) and approval of title, privacy, and assets before publishing.

## Performance notes
- World budget is printed at server start (`World budget: N parts, N lights`).
- Only the nearest 12 / 6 / 0 spotlights cast shadows (High / Mid / Low).
- Fireflies scale with quality and turn off with reduced motion.
- Streaming is on; key props are Persistent so they never stream out.
