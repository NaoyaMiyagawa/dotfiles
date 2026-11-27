---
name: custom-general-coding
description: Language-agnostic coding rules (guards, structure, logic placement, dependencies) and mandatory review gate. Use before writing, refactoring, or reviewing code in any language.
---

# General Coding Rules

Core rules to hold in mind while writing. Detailed comment, naming, and formatting rules live in [references/checklist.md](references/checklist.md) and are enforced by the review gate.

## Guards

- **Prove It Before Guarding**: Don't add a guard, fallback, refetch, or `catch` for a state you haven't traced as reachable (e.g. optional constructor arg never omitted, null check on non-nullable value). Leave unreachable paths bare.
- **Guard Clauses Over Nesting**: Invert the condition and bail early (`return`/`continue`), then write the main path unindented after a blank line. Consecutive guards sit together with no blank line between them.
- **Cheap Check First**: Run checks that can end work early (feature flag, in-memory field) before queries or fetches.
- **Confirmations Default To No**: Interactive prompts confirming writes or sends default to no.

## Structure

- **Extract A Repeated Call Pattern**: Move repeated calls with identical options into one named helper/module (check for an existing utility first) and put its why-comment there.
- **Methods Read As Steps**: Multi-step methods (handlers, middleware, services) read as a short list of named calls. Extract each step into a private function even with one caller (inline only one-liners). Number steps with comments (`// 1. ...`) when steps span multiple statements.
- **Merge Helpers Always Called Together**: If two complementary helpers are only ever called as a pair from the same site, combine them into one function returning both (`{ available, unavailable }`).
- **Widen The Helper, Not The Callers**: When a shared helper's parameter type forces callers to reshape data they already hold, widen the helper instead so call sites stay clean.
- **Copy Stable Keys, Not Mutable Labels**: Denormalized copies (search index, cache) store related IDs, not mutable display names — resolve names at read time. Historical snapshots (invoices, issued documents, audit entries) are the exception.

## Where logic lives

- **Validate Configuration On Save**: Validate user-edited config when saved/published; consumers trust it instead of re-checking on every run.
- **Mark A Side Effect Where It Happens**: Set side-effect timestamps/flags (`sent_at`) right beside the call that performs the effect.
- **Reuse The Variant Already In Use**: Match the module's existing algorithm, library, or format; a second variant needs a stated reason.
- **Read Fixed Values From The Loaded Schema**: Read fixed values from a schema/spec the code already loads instead of hardcoding a second copy.
- **API Errors Carry A Code**: Include a stable error code/type string alongside HTTP status and message.
- **A Feature Flag Gates Availability Only**: Flags decide whether an option exists; per-record behavior is a setting on that record.
- **Null Must Still Clear A Field**: Don't backfill omitted/null input from a previous record deep in a shared write path (`$input ?? $latest->value`); let callers pass carried-over values explicitly.

## Dependencies and swaps

- **Fix Dependencies At The Root**: Remove unused vulnerable/stale deps, or bump the direct dep. Package-manager overrides/pins are a last resort with a comment stating when they can go.
- **A Swap Keeps The Output**: Replacing a library behind an existing output (PDF, export, serializer) must match visually and structurally; cosmetic diffs are defects to fix before presenting.

## Review gate

Applies when the language skill has a `references/checklist.md`. Changed code is not done until it passes these steps in order before presenting or committing. For a small diff, skip the workers and do steps 2–3 in-session.

1. **Tooling.** Run the repo's formatter, linter, static analysis, and tests. No model reviews what tooling enforces.
2. **Bug review.** Send the diff to Codex for bugs and missed requirements per `~/dotfiles/.ai/docs/CODEX.md` (fall back to Claude Opus on Codex rate/usage limits). Fix findings yourself.
3. **Style pass.** `git add` changed paths, then hand a cheap worker (Claude Haiku; Sonnet if Haiku misses rules) the staged diff, [references/checklist.md](references/checklist.md), and the language skill's core rules + checklist. Brief:
   - Edit only lines the diff changed.
   - Apply a fix only when it leaves every signature, file, query, and output unchanged; otherwise report file, line, and rule.
4. **Read the worker's diff.** `git diff` now shows only the worker's edits. Rerun linter/tests, fix reported violations, and in test files verify changed assertions/mocks still test the same behavior.
