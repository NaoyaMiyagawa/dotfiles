---
name: custom-gh-dependabot-assess
description: Assess dependency bump PRs — Dependabot's or a dev's own — and post a short risk comment on each: what the package does, where the repo uses it, what the bump changes, and whether merging can break the app. Use when the user asks to assess, review, or check Dependabot PRs, asks what's in the Dependabot queue, passes PR numbers with "reassess", or has just created a PR that changes package.json, composer.json, or a lockfile.
metadata:
  short-description: Post a short risk assessment comment on Dependabot PRs
---

# Dependabot PR Assessment

Turn a dependency bump PR into a two-line answer a dev can act on without opening the diff: a risk badge with a recommendation, and the evidence folded underneath. Read-only on the repo. Never run the test suite; CI already does.

Prereq: `gh auth status` passes. Repo = the one the current directory is in.

## Workflow

1. **Select PRs.** Arguments win: PR numbers or URLs, `all`, and the flag `reassess`. Human-authored bump PRs are reached by argument only. Without arguments, list Dependabot's and let the user multi-select:
   ```bash
   gh pr list --author app/dependabot --state open --json number,title,comments,reviews \
     --jq '.[] | {number, title,
       assessed: ([.comments[].body | select(contains("<!-- dependabot-assessment -->"))] | length > 0),
       human_comments: ([(.comments[], .reviews[]) | select(.author.login | test("^app/|\\[bot\\]$|^(github-actions|dependabot|renovate)$|^copilot-") | not)] | length)}'
   ```
   Show number, title, `assessed`, `human_comments`. Skip `assessed` PRs unless `reassess` was passed; say so in one line per skipped PR. When the run cannot prompt (non-interactive), print the list and stop.
2. **Read the PR.** `gh pr view <n> --json title,body,commits,headRefOid,statusCheckRollup,url`. Parse the `updated-dependencies:` YAML trailer in the first commit body: `dependency-name`, `dependency-version`, `dependency-type` (`direct:production` / `direct:development` / `indirect`), `update-type` when present, `dependency-group` for grouped PRs. Bump type = `update-type` when present, else the semver diff of the versions in the title; on a grouped PR with neither, read the old version from `gh pr diff <n>` on the manifest. For grouped PRs, assess only `direct:*` packages and count the rest. A human-authored PR has no trailer: take package, old and new version from the manifest hunks of `gh pr diff <n>` (`package.json`, `composer.json`, workflow files), category from which dependency block the line sits in, and treat more than one changed direct package as a group.
3. **Assess each package.** Fill the four sections below. Every claim about a breaking change or advisory carries a deep link to its release note, changelog heading, or advisory page.
4. **Decide the risk.** Apply the [risk rules](#risk-rules). Fill `templates/single.md`, or `templates/group.md` when the trailer has `dependency-group` and more than one direct package. Recommendation is one of the three fixed forms.
5. **Post.** Write the body to a scratch file, then `gh pr comment <n> --body-file <file>`. On `reassess`, edit the existing marker comment instead: find its `id` via `gh pr view <n> --json comments --jq '.comments[] | select(.body | contains("<!-- dependabot-assessment -->")) | .id'`, then `gh api -X PATCH /repos/{owner}/{repo}/issues/comments/<id> -F body=@<file>`. One assessment per PR, always.
6. **Report.** One line per PR in chat: number, risk badge, recommendation, comment URL. Done when every selected PR has a comment URL or a skip reason.

Work PRs sequentially by default. In Claude Code, one worker per PR (max 2 concurrent) is allowed; the orchestrator reads every comment body before it is posted.

## Sections

**What it does.** One or two sentences from the registry description or README. Say what the app relies on it for, not what the marketing page says.

**Where it's used.** Category decides the method:
- `direct:production` — grep imports. npm: the package name in `import`/`require`. Composer: the PSR-4 namespace from `vendor/<pkg>/composer.json` `autoload.psr-4`, not the package name (`spatie/laravel-permission` → `Spatie\Permission`). Laravel packages also surface with zero `use` statements: facades, auto-discovered providers, `config/*.php`, so grep those too and write "no direct imports" rather than "unused". Map hits to pages by route entry (React router files, `routes/*.php`) when derivable; skip the page line otherwise. List up to 10 paths, then "+N more across `<dirs>`".
- `direct:development` — grep the same way; hits land in tests, scripts, or config (`vite.config.*`, `phpunit.xml`, `eslint.config.*`). Name the files and the pipeline stage they drive (lint, test, build), and say plainly that runtime code does not import it.
- `indirect` — "required by X, Y" from the lockfile. No grep.
- GitHub Actions — workflow files under `.github/` that reference the action.

**What changed.** Dependabot's PR body already folds release notes and commits. Use it first. When it is truncated, absent, or does not cover the whole version range, `gh api repos/<owner>/<repo>/releases` for the range. For a major bump also read the upstream `UPGRADE.md` / `CHANGELOG.md` at the new tag via `https://raw.githubusercontent.com/<owner>/<repo>/<tag>/<path>`; the Contents API rejects tag names containing `@`. Security PRs: `gh api /advisories/<GHSA>` for `severity` and `vulnerabilities[].vulnerable_functions`; when the list is empty, write "reachability not determinable from advisory", never a guess.

**Risk.** For every removed, renamed, or behaviour-changed API named in the notes, grep the repo and list hits with paths, or state "no usages of the changed APIs found". Check `.github/dependabot.yml` ignore rules and exact-version pins in `package.json` / `composer.json`; a pin is a past decision the reader would not know about.

## Risk rules

- 🟢 **Low** — patch or minor with no breaking notes, or a major whose changed APIs have zero hits in the repo **and** CI is green.
- 🟡 **Medium** — breaking notes exist and the grep hits are few and named, or a major bump where CI is green but the notes are unclear.
- 🔴 **High** — grep hits on a removed API, a security fix whose vulnerable path is used here, or CI is red.
- CI status (`statusCheckRollup`) is an input only. Red CI never yields Low. Green CI alone never yields Low on a major bump.
- Recommendation, exactly one of: `merge` · `merge after checking <file or symbol>` · `hold, needs a code change`. The check target is a concrete path or symbol, never "review carefully".
- Group PR: Risk = highest across direct packages. Per-package detail blocks only for major or breaking packages; the rest get a table row.

## Comment rules

- Two visible lines (`**Risk:**`, `**Summary:**`), one `<details>` fold, footer, marker. No `#` headings anywhere.
- `{{category}}` label: `direct:production` → `prod (direct)`, `direct:development` → `dev (direct)`, `indirect` → `prod (transitive)` or `dev (transitive)` from the lockfile (npm `"dev": true`, Composer `packages-dev`), GitHub Actions → `ci`.
- No sentence about CI status, not even inside the fold. The PR page already shows it.
- Single PR under about 40 lines, group under about 80. The diff holds the detail; this is the map.
- Footer time from `date '+%Y-%m-%d %H:%M %Z'`, tool name = whichever agent ran it.
- Keep `<!-- dependabot-assessment -->` as the last line; step 1 depends on it.
