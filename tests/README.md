# Tests

## Automated (pure logic)
`src/server/Tests/SelfTests.luau` runs at Studio server start (`FeatureFlags.RunSelfTestsOnStart`)
and from the command line:

```bash
python3 scripts/run_self_tests.py
```

Cases:
- shipped config passes the validator
- validator catches overlong dialogue, missing translations, broken triggers, missing evidence,
  timers on safety-critical lights, bad asset ids
- Leo starts polluted with safe paths lit; responsible fixes restore it; one shield alone does not
- safety-critical and useful lights cannot be switched off; DIM stops at the safety floor;
  safety light timer stays all night
- shield + aim reduce glare and sky glow and remove the glare zone
- unknown verbs/options are refused; scoring is deterministic

## Manual (Roblox Studio)
Solo, two-player, accessibility, and mobile steps: `docs/milestones/m1-leo-slice.md`.
Log every run in that file's results table.
