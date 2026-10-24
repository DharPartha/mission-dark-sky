# Companion Website (community report to PDF)

A small static page in `site/` that turns the report players copy from the game into a printable
PDF. It runs entirely in the browser: no account, no sign-in, no database, no upload, no analytics.
The Content-Security-Policy blocks all network connections (`connect-src 'none'`).

## How players use it
1. In the game: Star Journal → **Community report** (or the button on the end card).
2. Pick a restored place, a recommendation, and a reflection (preset buttons).
3. Select all the text in the box and copy it (Roblox games cannot write to the clipboard).
4. Open the website, paste, **Show my report**, then **Save as PDF** (the browser's print dialog).
If the website is unavailable, the copied text is a complete report on its own.

## Optional real-world section
Separate fields on the page for observations made **outside Roblox with a trusted adult**. They print
under their own heading ("added outside the game — not game evidence") and are never mixed with the
simulated game evidence. The page reminds players never to climb, touch, unscrew, or rewire fixtures.

## Report format
`DARKSKY-REPORT v1` plain text, written by `src/shared/Shared/ReportBuilder.luau` and read by
`site/parser.js`. To change the format, bump the version in both and update the tests.

## Tests
```bash
python3 scripts/run_self_tests.py --emit-sample site/tests/fixtures/sample-report.txt
node --test site/tests/
```
The first command regenerates the fixture from the game's own builder, so the site test proves the
website reads exactly what the game writes. The site tests also check that the page never inserts
HTML from the report and makes no network requests.

Local preview: `python3 -m http.server 8765 --directory site`, then open http://localhost:8765
(also available as the `companion-site` entry in `.claude/launch.json`).

## Deploy to GitHub Pages
1. On GitHub: **Settings → Pages → Build and deployment → Source: GitHub Actions**.
2. Merge to `main`. The `Companion site` workflow runs the tests, then publishes only
   `index.html`, `styles.css`, `parser.js`, and `app.js`.
3. Copy the published URL from the workflow run (or Settings → Pages).
4. Put it in `src/shared/Config/ExperienceConfig.luau` → `CompanionSiteUrl` (must start with
   `https://`). Until then the game tells players to ask a teacher or parent for the link.
