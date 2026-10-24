# Learning Evaluation (privacy-conscious)

The game sends **anonymous, aggregate** custom analytics events only (Roblox Creator Dashboard →
Analytics → Custom Events). Each event is a name from `Config/AnalyticsConfig.luau` plus at most one
number. No names, chat, free text, report text, locations, or other personal details are sent.
In unpublished Studio files events are printed to Output instead of sent.

## Optional targets (from the spec — goals to evaluate, not promises or results)
| Target | How to measure with the events |
|---|---|
| 45% of starters reach the pledge | unique players with `pledge_made` ÷ unique players with `session_start` (first sessions) |
| 25-point improvement on the 3-question check | mean of `quiz_post_score` vs mean of `quiz_pre_score` (as % of 3); `quiz_change` gives the per-player difference |
| 70% correct evidence-based decisions in the final act | `final_claim_correct` ÷ (`final_claim_correct` + `final_claim_incorrect`) |

## Other learning signals
| Signal | Events |
|---|---|
| Investigating | `evidence_found` (team evidence count), `mission_step` |
| Comparing solutions / using evidence | `moon_tip_correct`, `moon_tip_incorrect` |
| Preserving safety lighting | `unsafe_action_refused` (attempts the rules blocked) |
| Needing help | `auto_hint_shown`, `hint_requested` |
| Finishing | `realm_restored`, `ending_reached`, `pledge_made`, `report_generated` |

Report the actual sample size with any result. Small classroom samples are not statistically
reliable; treat them as feedback, not proof. Quiz questions are placeholders until the owner reviews them.
