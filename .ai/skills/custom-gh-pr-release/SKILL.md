---
name: custom-gh-pr-release
description: Create or update the release pull request (main <- develop) — an audience-friendly release summary split into user-facing vs internal changes, plus release caution checks (new env keys, external-app impact). Use when the user asks for a release PR or a PR from develop to main, or asks to write or summarize the description of a PR whose base is main and head is develop.
---

# Custom GitHub Release PR

Create the PR that merges `develop` into `main`. Its description is release notes for a mixed audience — developers, product managers, designers, customer success — so non-devs must be able to read the user-facing section.

## Workflow

1. **Collect the changes.** Run `git fetch --all`, then build the change list from `git log origin/main..origin/develop --first-parent --oneline`. Extract PR numbers from merge/squash subjects and use PR titles/bodies (`gh pr view`) as the primary material; open a diff only when a PR's impact is unclear. Done when every commit in that range is accounted for in your list.
2. **Write the summary** per the Description format below.
3. **Run the release caution checks** below and add their section.
4. **Create the PR**: base `main`, head `develop`. Match the title convention of previous release PRs (`gh pr list --base main --state merged --limit 5`); if there is none, use `Release YYYY-MM-DD`. Assign @NaoyaMiyagawa. If a develop→main PR is already open, `gh pr edit` its body instead of creating a new one.

## Description format

Two top-level sections — this split is the whole point:

- **User-facing changes** — anything a user, customer, or internal operator will notice: new features, page/UI changes, behaviour changes, bug fixes users hit. Plain language, lead with the outcome ("Issuers can now bulk-revoke documents"), no code identifiers. Start each bullet with a bold type prefix: `**New feature:**`, `**UI change:**`, `**Behaviour change:**` or `**Bug fix:**`.
- **Internal changes** — refactors, CI/tooling, performance, test-only work. Terse dev language is fine.

Within each section, group bullets under a `###` category heading named by what they touch: `Xxx feature`, `Xxx page`, `CI`, etc. One bullet per change. Don't cite PR numbers or links anywhere in the description — the PR's commit list already carries them. Don't force a category onto a single stray change — an `Other` group is fine.

List dependency changes under a `### Dependency upgrades` heading in Internal changes, one line per direct dependency (those named in `composer.json` or `package.json`), BE first: `- BE: vendor/package (1.0.6 -> 1.1.5)` or `- FE: package (1.61.0 -> 1.65.0)`. Take both versions from the lockfile diff between `origin/main` and `origin/develop`, not from PR titles. A newly added package reads `(new, 0.1.13)`. Skip transitive-only changes.

If the repo's PR template doesn't fit release notes, this format takes precedence.

## Release caution checks

Add a `## Release cautions` section (no emoji in the title). Verify each check against `git diff origin/main...origin/develop` — don't guess from PR titles:

- **New/changed env keys** — diff `.env.example` (and config files reading `env()`). List each new key and remind to set its value in every environment before deploy.
- **External-app impact** — changes to public API routes, request/response shapes, webhooks, events, or anything consumed by API consumers or sub-systems. Name which consumer is affected and how.
- **Also flag when present** — DB migrations (call out destructive or long-running ones), queue/scheduled-job changes, feature flags to toggle, one-off commands to run at deploy.

For every check, write the result even when it's `None` — the reader must see the check happened, not wonder whether it was skipped. Start each check line with ✅ when it is safe (None, or only a note that blocks nothing), and with ⚠️ when it needs action before deploy (a new env key, a destructive migration, an affected consumer).
