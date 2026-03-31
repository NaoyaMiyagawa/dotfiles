---
name: custom-git-committing
description: Committing code chanages in git. Use when you are making a commit.
---

# Custom Git Committing

## Commit Message
Do not use "--no-verify" "-n" option to ensure linting with pre-commit.

Construct a commit message based on the conventional-commit style. But, you don't need to use scope "()".

```yml
- feat: A new feature.
- fix: A bug fix.
- chore: Routine tasks, maintenance, or tooling changes that do not affect the main logic (e.g., updating configuration files or build scripts).
- docs: Documentation only changes.
- refactor: A code change that neither fixes a bug nor adds a feature (e.g., restructuring existing code).
- style: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc.).
- test: Adding missing tests or correcting existing tests.
- build: Changes that affect the build system or external dependencies.
- ci: Changes to CI configuration files and scripts.
- perf: A code change that improves performance.
- revert: Reverts a previous commit.
```

Write "why" or context rather than "what" and "how".

## Commit hash
Give me the commit hash after committing.
