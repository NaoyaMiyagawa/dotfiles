---
name: custom-pre-release-check
description: Pre-deploy check of a release tag — diff it against the tag production runs today and report what ops must do before and after deploying (secrets/env keys, migrations, one-off commands, infra) plus behaviour changes to tell customers. Use when the user is about to deploy a release tag or release to production/UAT/staging and asks what setup, env, or secret-manager changes are needed.
---

# Pre-Release Check

Answer one question for the person deploying: "what do I have to do besides pressing deploy?" Every claim comes from the diff between two refs, never from PR titles alone.

## Workflow

1. **Fix the range.** `git fetch --tags`, then `gh release view <tag>` for the release notes and its compare link. The baseline is the ref the target environment runs **now**, which is usually the previous tag deployed there. Release PRs merged to main without a tag are inside the range, not the baseline. If you can't tell what the environment runs, ask. Done when you can name `<baseline>..<tag>` and say why that baseline is right.
2. **Diff the setup surfaces.** Run each check against `git diff <baseline> <tag>`:
   - **Env/secrets:** `.env.example`, `config/**` and module config, and every added `env(` line. A key that exists in both refs is not new. Still flag it if new code starts depending on its value, for example a driver switch or a command that prints values to paste into a secret.
   - **Migrations:** list the added files and read each one. Flag destructive changes, long locks on big tables, a NOT NULL column with no default on a table that may have rows, and anything SQL Server handles differently (cascades, nullable unique). Say whether the table can hold rows in that environment.
   - **One-off commands:** new console commands. Read their docblock and signature to see whether one is a run-once provisioning step (keys, certificates, backfills), what credentials it needs, and what it outputs.
   - **Jobs/scheduler/queues:** new jobs, new queue names (does a worker listen on them?), scheduler entries.
   - **Dependencies:** `composer.json`/`package.json` direct additions. Flag any that need a PHP extension or a system package in the image.
   - **Deploy pipeline:** the deploy workflow for that environment and the Docker/infra files.
   - **Feature flags:** added or renamed flag keys, and whether any need toggling at release.
   Done when every bullet has a verified result, even if that result is "none".
3. **Cross-check the release PRs.** Read the "Release cautions" section of each release PR (develop→main) merged in the range. Reconcile it with your findings. When they disagree, the diff wins, and you point out the disagreement.
4. **Report** in the format below.

## Report format

Lead with a one-line verdict: whether anything is required **before** deploy. Then:

- **Before deploy:** required actions only: secrets to set, infra to create. Give the exact key names and the environments they apply to.
- **After deploy:** one-off commands and optional activation steps, as ordered steps with the exact command. Add the prerequisites (credentials, dry-run first) and anything irreversible.
- **Checked, nothing needed:** one short line per surface that came back clean, so the reader can see it was checked.
- **Tell customers/CS:** externally visible behaviour changes, such as API shape, rejected requests, or UI rules.

Cite PR numbers. Keep the whole report short enough to read in one pass.

## Rules

- In zsh, quote `git show "<tag>:<path>"`. An unquoted `$T:a...` triggers zsh's `:a` modifier and breaks the path.
- Read-only. Don't set secrets, run provisioning commands, or deploy. Give the steps and let the user run them.
