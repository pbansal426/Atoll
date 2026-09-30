# Notch fork notes
- Upstream: Ebullioscopic/Atoll (remote `upstream`). Our branch: `notch-fork`.
- Spec/plans live in ~/Dev/Notch/docs/superpowers/.
- Sync: `git fetch upstream && git merge upstream/main` — conflicts should only touch `// NOTCH-FORK:` sites.
- Our code: DynamicIsland/notch-fork/. Core edits: grep `NOTCH-FORK:`.
## Known upstream failures
- `ClipboardHistoryPersistenceTests` (whole class): its tests seed and assert on
  `UserDefaults.standard`, which the test host shares with the running dev app
  (same bundle id). Live clipboard writes from that app make different tests fail
  at random (e.g. `("Optional(2439 bytes)") is not equal to ("Optional(2 bytes)")`).
  Skipped in the gate via `-skip-testing`.
## Non-code edits
- `DynamicIsland.xcodeproj/project.pbxproj`: app Debug `DEVELOPMENT_TEAM=HDV6WRH58B` and `PRODUCT_BUNDLE_IDENTIFIER=com.prathambansal.notch.dev`.
- `DynamicIsland/utils/SMC.swift`: write paths removed (fork is read-only), including the `writeBytes` enum case.
- `.gitignore`: negation so `scripts/notch-register-test.py` is tracked.
