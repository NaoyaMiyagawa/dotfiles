---
name: custom-git-committing
description: Committing code changes in git. Use when you are making a commit.
---

# Custom Git Committing

## Commit Message

- Never pass `--no-verify` / `-n` — pre-commit hooks (linting) must run.
- Use conventional-commit style (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `style:`, `test:`, `build:`, `ci:`, `perf:`, `revert:`), without the scope `()`.
- Write the *why* / context rather than the what and how.

## Committing ported / copied code

When vendoring or porting files from another source, commit the raw copy first, then make integration/adjustment edits as a separate commit. The reviewer can then diff your changes against the pristine copy instead of against nothing.

## After committing

Report the commit hash.
