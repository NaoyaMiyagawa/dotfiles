---
description: "Self-review current branch PR diffs against Laravel/PHP coding standards (read skills, then audit diffs)"
---

PR self-review: verify every line you (or this session) changed matches the coding standards captured in the dotfiles skills below. Cursor does not auto-load skills; you must **read each listed file in full** before judging the diff.

## Mandatory: load standards from these skill files

Read **every** path below (full file). Treat them as the source of truth for review criteria—not memory or generic Laravel/PHP advice.

**Laravel**

- `~/dotfiles/.ai/skills/custom-laravel-coding/SKILL.md`
- `~/dotfiles/.ai/skills/custom-laravel-writing-tests/SKILL.md`

**PHP**

- `~/dotfiles/.ai/skills/custom-php-running-linter/SKILL.md`
- `~/dotfiles/.ai/skills/custom-php-running-static-analysis/SKILL.md`
- `~/dotfiles/.ai/skills/custom-php-running-test/SKILL.md`

**Utils**
- `~/dotfiles/.ai/skills/ccc/SKILL.md`

## Get the change set to review

1. **Base branch**: Prefer the PR’s merge base. Use `gh pr view --json baseRefName,headRefName` when a PR exists for the current branch; otherwise use `develop`, `main` or `master` as the repo default (ask once if ambiguous).
2. **Diff**: `git fetch` if needed, then `git diff <base>...HEAD` (three-dot) for commits on this branch, or `gh pr diff` for the open PR. Include renames and note new/deleted files.

Scope the review to **files touched in that diff**. If the user’s intent is “my changes only,” say so; otherwise review the full branch diff vs base.

## Self-review (your own work)

You are doing a **self-review**: assume you authored or applied these changes. Check:

- Conventions from the Laravel skill(s) (structure, naming, framework patterns, refactors).
- Test conventions from the Laravel testing skill **for any test/factory changes**.
- Formatting and lint expectations from the PHP linter skill; static analysis expectations from the PHP static analysis skill; test execution/conventions from the PHP test skill **where relevant**.

Flag **violations, risks, and gaps** (missing tests, silent edge cases, inconsistent patterns), not generic praise.

## Output format

1. **Scope**: base ref, head ref, and how the diff was obtained.
2. **Summary**: pass/fail with brief rationale.
3. **Findings**: ordered by severity (blocking / should-fix / nit). Each item: file path, approximate location if possible, what standard it breaks (cite the skill section or rule), and a concrete fix.
4. **Residual risk**: what you could not verify from the diff alone.

Do not apply fixes unless the user asks; this command is for review output first.
