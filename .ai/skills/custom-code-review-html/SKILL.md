---
name: custom-code-review-html
description: Render a code review as a self-contained HTML report — findings in risk order, verbatim before/after code panes, per-finding triage (accept/reject/comment), and a markdown hand-off to paste back into the implementing session. Use when reviewing a large diff, branch, or PR and the user wants an HTML page or report instead of terminal output, when a review needs a checklist the human can work through one point at a time, or when another review skill needs a visual output format.
---

# Code Review HTML Report

A review dumped into the terminal is read once and scrolled past. This renders it as
a page the reviewer can **work**: findings ordered by how much logic rests on them,
each with the current code beside the proposed code, each triageable, and the accepted
set exportable as markdown for the session that will do the fixing.

The page is the delivery format. The review is the work — never let page-building
displace reading the diff.

## Workflow

### 1. Establish scope from the diff, not the description

PR → `gh pr diff <n>` plus `gh pr view <n> --json title,body,baseRefName,additions,deletions,changedFiles`.
Branch → `git diff <base>...HEAD`. That diff is the entire review scope; local
working-tree changes are out of scope unless the user says otherwise.

Done when you have the full diff on disk and know the base branch.

### 2. Blind pass

Review the diff **before** reading the PR body, spec, or plan. Judge the code as it
stands.

This exists to defeat one specific failure: given the plan first, a reviewer excuses
weak implementation because "it follows the plan," and the finding is never written
down. If you have already read the description, dispatch a subagent with only the diff
and no context to get an uncontaminated pass.

Done when every finding is written down with a concrete failure path — inputs or state
→ wrong behavior. Discard anything you cannot state that way.

### 3. Intent pass

Now read the description, plan, and linked ticket. Two jobs:

- **Keep** every blind-pass finding the plan does not actually dissolve. "The plan says
  so" is not a refutation of a real defect; note the tension instead.
- **Add** what only this pass can see: claims in the description the code does not
  support, and scope the plan promised that the diff omits.

Done when each blind-pass finding is marked kept-or-dissolved with a reason, and the
description's factual claims have each been checked against the code.

### 4. Prove before you publish

For every finding whose mechanism you inferred rather than observed, run something.
A throwaway spec that feeds the real runtime shape to the real predicate settles in
one minute what a paragraph of reasoning only asserts. **Delete the probe afterwards**
and leave the tree clean.

Where a library's behavior is load-bearing, read the installed source in
`node_modules` (or the vendor directory) rather than trusting its type declarations —
hand-written ambient declarations lie, and a finding built on the declared type
instead of the runtime value is exactly the kind that dies under review.

Then verify every citation: get each file's line numbers from a fresh search, never
from memory or from the diff's hunk headers. Cited line numbers that are off by two
cost you the reader's trust in everything else on the page.

Done when each finding is either observed-by-running or explicitly labelled as
reasoning, and every file:line on the page has been re-derived from the current
checkout.

### 5. Rank and group

Order by **how much logic rests on the finding**, not by file and not by severity
label alone. A dead check at the heart of the feature outranks five style issues.

Group by intent, not by file: a rename and the imports it drags along are one finding,
not seven. If a finding only matters because another one is true, say so in its body
and place it immediately after.

Done when the order is defensible top-to-bottom and no two findings describe the same
underlying cause.

### 6. Build the page

Copy `assets/report-template.html` and fill it in. It already carries the working
machinery — theme tokens, sticky navbar, EN/JA switch, triage with localStorage,
markdown hand-off — so do not rebuild any of that. Clone the marked `<article>` block
per finding.

Read the template's inline comments; they say what each region is for.

### 7. Validate, then publish

```
python3 scripts/check-report.py <report.html>
```

Fix everything it reports. It catches unbalanced tags, an unpaired language block,
font-relative widths, and inline JS that does not parse — all of which look fine in a
skim and break in the browser.

Publish with the Artifact tool if available, otherwise write the file and `open` it.
Relay the top findings in chat too: the user should not have to open the page to learn
whether the change is sound.

Done when the checker exits 0 and the user has both the link and the headline finding.

## Page rules

- **Self-contained.** Inline all CSS and JS; no CDNs or web fonts. Mermaid via
  `<pre class="mermaid">` renders natively in Artifacts — for an offline file, hand-write
  inline SVG instead.
- **No document skeleton.** No `<!doctype>`, `<html>`, `<head>`, or `<body>` — the
  artifact host wraps the file.
- **The `now` pane is copied, never retyped.** Both panes keep code and code comments
  in the source language, so the suggestion stays paste-ready.
- **Every finding carries its `data-*` pair.** Those attributes are all the implementer
  receives through the hand-off, so each must read as standalone prose — not "as above"
  or "the same as 02".
- **A finding with no code change says so.** An empty compare block reads as an
  omission; a line stating that the fix is a description change or a sign-off does not.
- **Praise is specific or absent.** Cut the "what it gets right" section rather than
  padding it.
- **`{{STORAGE_SLUG}}` must be unique per report.** Triage lives in localStorage keyed
  by it; reuse a slug and the new review opens with the previous one's verdicts already
  applied. Leave no `{{PLACEHOLDER}}` unreplaced anywhere — grep for `{{` before
  publishing.

## Bilingual pages

Only when the user wants a second language. Both languages ship as real `lang="en"` /
`lang="ja"` markup with one hidden by CSS — never machine-translated at view time.

The whole risk here is **layout drift**: if the column or the type metrics change with
the language, the passage under the reader's eye moves and switching becomes
unpleasant enough that they stop doing it. Three rules prevent it, and the template
already obeys all three:

- **Widths in `rem`, never `ch` or `em`.** A font-relative measure resizes the entire
  column when the font stack changes.
- **One type scale for both.** Per-language `font-size` and `line-height` overrides are
  the drift. If the display face lacks the second script's glyphs, extend the font stack
  to cover both scripts — fallback resolves per character — rather than switching family
  by language.
- **Anchor the scroll across the switch.** Record the block nearest the viewport top and
  its offset, swap, then correct the scroll by the drift.

Translate prose, headings, severity words, and UI labels. Leave code, identifiers,
file paths, and line numbers untranslated in both.

A keyboard shortcut must not fire while the user is typing: skip when the event target
is an input, textarea, or contenteditable, when a modifier is held, and during IME
composition (`isComposing`, plus `keyCode === 229` for the keystroke that starts it).
For a romaji IME this is not an edge case — the shortcut letter appears in ordinary
Japanese text constantly.
