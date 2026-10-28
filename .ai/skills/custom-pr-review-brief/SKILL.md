---
name: custom-pr-review-brief
description: Brief a human reviewer on a PR, branch, or diff before or during their manual review — a plain-language "currently / after this PR / why" summary per change, then bugs, simpler alternatives, and better ways to write it, grouped by severity and category in chat. Use when the user is about to review or is reviewing a PR and asks what it changes, wants a summary before reviewing, asks to "brief me on", "walk me through", or "pre-review" a PR, asks what changed since their last review, or asks for bugs and alternatives in someone else's change. Not for posting comments on the PR or for an HTML report (use custom-code-review-html).
---

# PR Review Brief

The reader is about to review this change by hand. Give them two things: what the change
does in words they can check against the code, and what they should look at hard. Output
goes in chat only; never post to the PR.

## 1. Scope

- PR number or URL → `gh pr diff <n>` and `gh pr view <n> --json title,baseRefName,commits`.
- Branch → `git diff <base>...<branch>`; no target → the current branch's PR, else `git diff origin/develop...HEAD` (`origin/main` where develop doesn't exist).
- `since last review` → only the commits after the last brief in this conversation, or after the user's last PR review (`gh pr view <n> --json reviews,commits`). Summarize those commits, and list each earlier finding as `addressed`, `still open`, or `changed differently`.

Read the whole diff before the PR body, so the summary describes the code, not the author's
claim about it.

Start the Codex pass from section 3 now, in the background, so it runs while you read.

## 2. Summary

Split the diff into concerns (one behavior, fix, refactor, or migration each; may span
files). For each concern:

- **Currently:** what the system does today, in user or caller terms.
- **After this PR:** what it does after merge.
- **Why:** from the PR body (`gh pr view <n> --json body`, read now, after the diff), commit messages, or linked ticket. If none of those say it, write `Why (inferred):` and your best reading.

Plain words, one or two sentences per line. Name the files only in a trailing
`Files:` line. Skip concerns that are pure noise (lockfile churn, generated code) but list
them in one line so the reader knows they were seen.

End with one `Start reading at:` line naming the file the rest of the diff follows from.

## 3. Findings

**Standards:** before judging, read the coding skill for each changed file type and its
`references/checklist.md` when present: `custom-laravel-coding` for PHP,
`custom-laravel-writing-tests` for Pest tests, `custom-react-coding` for React/TSX. A
violation of those rules is a finding; cite the rule.

**Bugs:** run steps 1–6 of the `evidence-code-review` workflow on the diff to find and
validate defects; section 4 below replaces its output contract. Its style filter applies to
this bug pass only, not to the alternatives below. Keep only findings with a concrete failure
path: inputs or state → wrong behavior. Give each bug a repro and why the change causes it.
The repro is the user flow a reviewer clicks through, or for backend-only code the request or
command (`POST /orders with qty=0 → 500`). Mark it `verified` only if you ran it; otherwise
`not run`.

**Codex pass:** run a Codex review of the same diff per the `codex` skill. Give it the diff
only, no PR body and no summary, so it judges the code unprimed. Confirm each Codex finding
against the code before merging it in; drop duplicates and say in `Not checked` if Codex
failed or timed out.

**Alternatives and better ways to write:** limited to lines this diff adds or changes. A
suggestion qualifies only when it does at least one of:

- removes code or a branch,
- reuses a helper, component, or pattern already in this repo (name it with `file:line`),
- uses a platform or installed-library feature that replaces hand-written code,
- handles an edge case the current version misses,
- follows a rule from the standards skills above that the diff breaks.

State the concrete gain. "Cleaner" or "more idiomatic" alone is not a gain; drop it.

Tag each finding `introduced` or `pre-existing`. Report pre-existing issues only when the diff
makes them worse.

## 4. Output

Severity first, category second. Omit empty severities and categories. Number findings once
across the whole list (1, 2, 3, …) so the user can follow up with "explain #3" or "post #2".
Posting goes through `difit-review` or `custom-gh-address-comments`, only when asked.

- **Blocking** — breaks behavior, loses or exposes data, or fails in production.
- **Should fix** — wrong in an edge case, missing test for new logic, a standards violation, or a reuse that avoids a real divergence.
- **Optional** — alternatives and better ways to write that don't fix a defect.

Categories: Bug, Security, Data, Tests, Standards, Alternative, Readability. Add another only
when none fit. Mark findings that came from Codex with `(codex)`.

````markdown
## Summary
**1. <concern title>**
- Currently: ...
- After this PR: ...
- Why: ...
- Files: `a.php`, `b.tsx`

Also touched (no review needed): lockfile, generated types.
Start reading at: `app/Services/OrderService.php`

## Findings
### Blocking
**Bug**
1. `path/file.ext:42` — <one-line claim>. Repro (not run): <flow or request>. Cause: <why the change does this>. (introduced)

### Should fix
**Standards**
2. `path/file.ext:60` — <rule broken> (`custom-laravel-coding`). (introduced)

### Optional
**Alternative**
3. `path/file.ext:88` — <suggestion>. Gain: <concrete gain>.
   ```lang
   // current → proposed, a few lines each
   ```

## Not checked
<what you skipped: tests not run, dynamic callers not traced, files too large to read>
````

If there are no findings, say so in one line under `## Findings`. Don't pad.
