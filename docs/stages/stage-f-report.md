# Stage F — Learning Check, Evaluation, Community Report, Companion Website

## What changed
| Area | New / changed |
|---|---|
| Post-check | `QuizConfig.Quizzes.post` (same 3 questions); finale step `postcheck` after the ending; shows "At the start: X of 3. Now: Y of 3." plus the correct answers |
| Evaluation | New anonymous events: `quiz_post_score`, `quiz_change`, `final_claim_correct/incorrect`, `evidence_found`, `report_generated`; formulas in `docs/evaluation.md` |
| Report | `Config/ReportConfig` (fictional places, alternatives with pros/cons, trade-offs, essential lighting, reflections), `Shared/ReportBuilder` (`DARKSKY-REPORT v1`), `ReportController` (preset choices, selectable copy box, site instructions) |
| Access | End card button and Journal button "Community report"; instructions stay in the Journal after the story |
| Website | `site/` static page: paste → preview → Save as PDF (print), copy fallback, optional adult-verified real-world section printed separately, CSP blocks all network connections |
| Deploy | `.github/workflows/pages.yml` (tests, then publishes only the 4 page files); URL goes in `ExperienceConfig.CompanionSiteUrl` |
| Tests | 40 Luau self tests (report format), 11 website tests (parses the game's own sample, errors, markup stays text, no network) |

## Verified here
- `node --test site/tests/` — 11 passed.
- Website opened in the built-in browser via `python3 -m http.server`: pasted the game's sample report,
  the preview rendered every section and the alternatives table, the real-world block printed separately,
  no console errors, and no horizontal scrolling at 375 px phone width. (The print dialog itself was not opened.)

## Studio tests
| # | Do | Expected |
|---|---|---|
| 1 | Output | `Self tests: 40 passed`, no config errors |
| 2 | Finish the ending (or Jump to Act III and play through) | After returning home: "Sky check: after"; results show start vs now and the answers |
| 3 | Pledge, then end card | End card shows site instructions and "Write a community report" |
| 4 | Report screen | Only places you restored are listed; pick place, recommendation, reflection; "Create my report" |
| 5 | Copy | Click into the box, Ctrl/Cmd+A, Ctrl/Cmd+C; paste into the website: preview matches |
| 6 | Journal → Community report | Still available after the story |
| 7 | Output (local file) | `[DarkSky] analytics report_generated`, `quiz_post_score`, `quiz_change` lines |

## Owner steps
1. Enable GitHub Pages (Settings → Pages → Source: GitHub Actions) and merge to `main`.
2. Put the published `https://` URL into `ExperienceConfig.CompanionSiteUrl`.
3. Review `ReportConfig`, `QuizConfig`, and `PledgeConfig` wording.

## Known limitations
- Roblox cannot write to the clipboard; players select and copy the text themselves.
- On some phones, selecting text inside Roblox TextBoxes is awkward; the website also accepts
  text typed or shared another way, and the report is useful as plain text.
