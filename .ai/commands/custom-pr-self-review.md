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

## PHPStan (must be clean)

In the **application repository** (the repo whose PR you are reviewing), when PHP is in scope for that project and `phpstan` is available:

1. Follow `~/dotfiles/.ai/skills/custom-php-running-static-analysis/SKILL.md` for **how** to invoke PHPStan (e.g. Sail vs plain `vendor/bin/phpstan`).
2. Run analysis on an appropriate scope for this change set (at minimum: all PHP files touched in the branch diff vs base; use the skill’s file-targeted command when possible instead of full-app unless you need it).
3. **Requirement**: PHPStan must complete with **no errors** (exit zero, no reported issues at the configured baseline/level). If it fails, treat that as **blocking**: overall summary is **fail**, list PHPStan findings first under **Findings**, and do not imply the branch passes review until those are resolved or you explicitly note why PHPStan could not be run (e.g. workspace is dotfiles-only, no `vendor`, or project does not use PHPStan).

## Self-review (your own work)

You are doing a **self-review**: assume you authored or applied these changes. Check:

- Conventions from the Laravel skill(s) (structure, naming, framework patterns, refactors).
- Test conventions from the Laravel testing skill **for any test/factory changes**.
- Formatting and lint expectations from the PHP linter skill; static analysis expectations from the PHP static analysis skill; test execution/conventions from the PHP test skill **where relevant**.

Flag **violations, risks, and gaps** (missing tests, silent edge cases, inconsistent patterns), not generic praise.

## Output format

1. **Scope**: base ref, head ref, and how the diff was obtained.
2. **PHPStan**: command(s) run, scope, pass/fail; if skipped, say why.
3. **Summary**: pass/fail with brief rationale (must be **fail** if PHPStan reported errors or exited non-zero when it was applicable to run).
4. **Findings**: ordered by severity (blocking / should-fix / nit). Each item: file path, approximate location if possible, what standard it breaks (cite the skill section or rule), and a concrete fix.
5. **Residual risk**: what you could not verify from the diff alone.

Do not apply fixes unless the user asks; this command is for review output first.
