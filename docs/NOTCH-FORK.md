# Notch fork notes
- Upstream: Ebullioscopic/Atoll (remote `upstream`). Our branch: `notch-fork`.
- Spec/plans live in ~/Dev/Notch/docs/superpowers/.
- Sync: `git fetch upstream && git merge upstream/main` — conflicts should only touch `// NOTCH-FORK:` sites.
- Our code: DynamicIsland/notch-fork/. Core edits: grep `NOTCH-FORK:`.
## Known upstream failures
- `ClipboardHistoryPersistenceTests/testLaunchPurgeLeavesStoredHistoryAloneWhenEnabled` (ClipboardHistoryPersistenceTests.swift:338):
  `XCTAssertEqual failed: ("Optional(1492 bytes)") is not equal to ("Optional(2 bytes)")`.
  Fails on the unmodified upstream test in this environment (the hosted app's live clipboard history writes over the "[]" it seeds). Skipped in the gate via `-skip-testing`.
