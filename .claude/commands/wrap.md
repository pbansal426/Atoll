---
description: End-of-day wrap - gate, commit, push, clean worktrees, write STATUS
---
1. Run the gate. If it fails, STOP and report - do not commit.
2. Stage and commit with a concise conventional-commit message.
3. Push the current branch (skip if no remote).
4. Remove merged/finished worktrees; delete merged local branches.
5. Update/create STATUS.md: Done / Next / Known issues.
6. Confirm: no uncommitted changes, no dangling worktrees.
