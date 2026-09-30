# Atoll — agent operating rules

## Golden rules
- Query the graphify graph in graphify-out/ before grepping, if it exists.
- New/changed behavior ALWAYS ships with tests. Never declare done until the gate passes.
- Gate: xcodebuild -project DynamicIsland.xcodeproj -scheme DynamicIsland -configuration Debug -destination 'platform=macOS' -derivedDataPath build-test -allowProvisioningUpdates -only-testing:DynamicIslandTests -skip-testing:DynamicIslandTests/ClipboardHistoryPersistenceTests/testLaunchPurgeLeavesStoredHistoryAloneWhenEnabled test -quiet
- Never touch .env, secrets, or golden-set fixtures without explicit approval.
- If the gate fails twice on the same root cause, STOP and report the blocker.

## Delegation policy
- Plan first, get my approval on the PLAN, then execute autonomously.
- Use subagents for noisy read/search/review; return concise summaries.
- Cross-check important changes with a different model before finishing.
- At completion, show the RUNNING RESULT, not the raw diff.

## Definition of done
Gate green - tests added - STATUS.md updated - no dangling worktrees/branches.

## Notch fork rules
- Spec: ~/Dev/Notch/docs/superpowers/specs/2026-09-29-notch-app-design.md — decisions there are final.
- New code in DynamicIsland/notch-fork/. Core-file edits carry a `// NOTCH-FORK:` comment.
- NEVER write fan state (no SMC writes). Fan changes only via `smctl` commands the user asked for.
- New test files must be registered: `python3 scripts/notch-register-test.py <File>.swift`.
- GUI checks: logs + one real user interaction; never synthetic AppleScript input.
