---
name: custom-git-committing
description: Committing code changes in git. Use when you are making a commit.
---

# Custom Git Committing

## Commit Message

- Never pass `--no-verify` / `-n` — pre-commit hooks (linting) must run.
- Use conventional-commit style (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `style:`, `test:`, `build:`, `ci:`, `perf:`, `revert:`), without the scope `()`.
- Write the *why* / context rather than the what and how.

## After committing

Report the commit hash.
