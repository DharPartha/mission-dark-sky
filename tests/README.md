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
- saves: new player, returning player across servers, read outage never overwrites, retry recovers,
  corrupt data backed up (and not replaced if backup fails), newer-version data left alone,
  live lock blocks / stale lock taken over / old server stops writing, migration and repair,
  journal de-duplication and cap
- rate limiter burst/throttle/refill; restored-fixture preset is safe and restores the zone;
  validator catches broken mission steps

## Manual (Roblox Studio)
Per stage: `docs/stages/`. Leo slice details: `docs/milestones/m1-leo-slice.md`.
Log every run in that file's results table.
