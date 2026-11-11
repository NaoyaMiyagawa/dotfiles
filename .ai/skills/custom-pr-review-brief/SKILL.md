---
name: custom-pr-review-brief
description: Brief a human reviewer on a PR, branch, or diff before or during their manual review — a plain-language "currently / after this PR / why" summary per change, then bugs, simpler alternatives, and better ways to write it, grouped by severity and category in chat, or as an HTML page when asked. Use when the user is about to review or is reviewing a PR and asks what it changes, wants a summary before reviewing, asks to "brief me on", "walk me through", or "pre-review" a PR, asks what changed since their last review, or asks for bugs and alternatives in someone else's change. Not for posting comments on the PR, or for a full HTML code review that is not a pre-review brief (use custom-code-review-html).
model: opus
---

# PR Review Brief

The reader is about to review this change by hand. Give them two things: what the change
does in words they can check against the code, and what they should look at hard. Output
goes in chat, or as a page in HTML mode (section 5); never post to the PR.

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

- **Why:** from the PR body (`gh pr view <n> --json body`, read now, after the diff), commit messages, or linked ticket. If none of those say it, write `Why (inferred):` and your best reading.
- **Currently:** what the system does today, in user or caller terms.
- **After this PR:** what it does after merge.

Plain words, one or two sentences per line. Name the files only in a trailing
`Files:` line. Skip concerns that are pure noise (lockfile churn, generated code) but list
them in one line so the reader knows they were seen.

End with one `Start reading at:` line naming the file the rest of the diff follows from.

## 3. Findings

**Standards:** before judging, read the coding skill for each changed file type and its
`references/checklist.md` when present: `custom-general-coding` for any code, `custom-laravel-coding` for PHP,
`custom-laravel-writing-tests` for Pest tests, `custom-react-coding` for React/TSX. These
rules are the user's own preferences, not the PR author's, so a violation (test-style rules
included) goes in the separate STANDARDS section, never in a severity; cite the rule.

**Bugs:** map what the diff changes, then trace each changed behavior through its callers,
data, and error paths, highest-risk areas first. Confirm every candidate against the code
before reporting it, and drop style-only or speculative ones; that filter applies to this
bug pass only, not to the alternatives below. Keep only findings with a concrete failure
path: inputs or state → wrong behavior. Give each bug a repro and why the change causes it.
The repro is the user flow a reviewer clicks through, or for backend-only code the request or
command (`POST /orders with qty=0 → 500`). Mark it `verified` only if you ran it; otherwise
`not run`.

Rate each finding that has a failure path (Bug, Security, Data) by impact, independent of
which section it lands in. Write the rating with its square, like `[🟧 Medium]`; squares keep
it apart from the circle severity headings:

- 🟥 **High** — hits a common flow, loses or exposes data, or stops a user from finishing a task.
- 🟧 **Medium** — wrong result in a reachable but uncommon case, or a common case with a workaround.
- 🟦 **Low** — rare edge case, or the effect is cosmetic or corrects itself on retry.

**Codex pass:** run a Codex review of the same diff per the `codex` skill. Give it the diff
only, no PR body and no summary, so it judges the code unprimed. Confirm each Codex finding
against the code before merging it in; drop duplicates and say in `Not checked` if Codex
failed or timed out.

**Alternatives and better ways to write:** limited to lines this diff adds or changes. A
suggestion qualifies only when it does at least one of:

- removes code or a branch,
- reuses a helper, component, or pattern already in this repo (name it with `file:line`),
- uses a platform or installed-library feature that replaces hand-written code,
- handles an edge case the current version misses.

State the concrete gain. "Cleaner" or "more idiomatic" alone is not a gain; drop it.

Tag each finding `introduced` or `pre-existing`. Report pre-existing issues only when the diff
makes them worse.

## 4. Output

Severity first, category second. Omit empty severities and categories. Number findings once
across the whole list (1, 2, 3, …) so the user can follow up with "explain #3" or "post #2".
Posting goes through `difit-review` or `custom-gh-address-comments`, only when asked.

- **Blocking** — breaks behavior, loses or exposes data, or fails in production.
- **Should fix** — wrong in an edge case, missing test for new logic, or a reuse that avoids a real divergence.
- **Optional** — alternatives and better ways to write that don't fix a defect.

Categories: Bug, Security, Data, Tests, Alternative, Readability. Add another only
when none fit. Standards findings go last in their own STANDARDS section, numbered on from the
rest, with no category line. Put the number and the bracketed category on their own line and the finding on
the next, with a blank line between findings. Within a severity, sort by category, then rated
findings by impact, High first. Mark findings that came from Codex with `(codex)`.

The terminal renders every heading level and `**bold**` alike, so section and severity
headings are UPPERCASE with the emoji below, each summary concern is a `###` heading so it
reads as its own block, each summary label is a bold paragraph line, not a bullet, because the
renderer drops blank lines between list items, and nothing else is bold.

````markdown
## 📋 SUMMARY
### 1. <concern title>
**Why:**
...

**Currently:**
...

**After this PR:**
...

**Files:**
`a.php`, `b.tsx`

### 2. <concern title>
**Why:**
...

**Currently:**
...

**After this PR:**
...

**Files:**
`c.php`

Also touched (no review needed): lockfile, generated types.
Start reading at: `app/Services/OrderService.php`

## 🔍 FINDINGS
### 🔴 BLOCKING
1. [Bug] [🟥 High]
   `path/file.ext:42` — <one-line claim>. Repro (not run): <flow or request>. Cause: <why the change does this>. (introduced)

### 🟡 SHOULD FIX
2. [Bug] [🟧 Medium]
   `path/file.ext:51` — <one-line claim>. Repro (not run): <flow or request>. Cause: <why>. (introduced)

3. [Bug] [🟦 Low]
   `path/file.ext:57` — <one-line claim>. Repro (not run): <flow or request>. Cause: <why>. (introduced)

### ⚪ OPTIONAL
4. [Alternative]
   `path/file.ext:88` — <suggestion>. Gain: <concrete gain>.
   ```lang
   // current → proposed, a few lines each
   ```

### 📏 STANDARDS
5. `path/file.ext:60` — <rule broken> (`custom-laravel-coding`). (introduced)

6. `tests/FooTest.php:12` — <rule broken> (`custom-laravel-writing-tests`). (introduced)

## ⚠️ NOT CHECKED
<what you skipped: tests not run, dynamic callers not traced, files too large to read>
````

If there are no findings, say so in one line under `## 🔍 FINDINGS`. Don't pad.

## 5. HTML mode

When the user passes `html` or asks for the brief as a page, do sections 1–3 as above, then
build the page with steps 6–7 of `custom-code-review-html` (its template, checker, and
publish step). That skill's steps 1–5 are replaced by this one, and so is its ranking: keep
this brief's order. Fill the template like this:

- **What it does** → one block per summary concern with its Why, Currently, After this PR,
  and Files, then the `Start reading at` line. Drop the diagram unless a concern has a
  control flow worth seeing.
- **Findings** → one article per Blocking, Should fix, and Optional finding, in that order.
  `data-sev`: Blocking `critical`, Should fix `high`, Optional `low`. Put the category and
  impact rating at the start of the title, like `[Bug] [🟧 Medium]`.
- **Nits** → retitle it Standards and list the standards findings there.
- **What the change gets right** → replace it with Not checked.

Write it in English only unless the user asks for Japanese (that skill's Bilingual pages). In chat, give only the page link and
the top finding.
