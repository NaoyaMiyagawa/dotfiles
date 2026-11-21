---
name: custom-general-coding
description: Language-agnostic coding rules — which comments to keep, guards, naming, paired helpers, denormalized copies, dependency fixes, and library swaps. Use when writing, refactoring, or reviewing code in any language, alongside the language skill when one exists.
---

# General Coding Rules

## Comments

- **Comments Carry Only What Code Can't Say**: Delete a comment that restates the code. A previous or deleted implementation belongs in git — not in a comment, and not in a decision note or doc either. A decision note doesn't repeat a why that a comment at the code site already states. Keep what a reader can't derive: why a line exists (`// for idempotency`), what a non-obvious block does to the data — say the effect, not just when it runs, in one line above it or as the name of a private method it moves into (`// drop validFrom from required until issuance fills it`), why a workaround is there and when it can go (a workaround module opens with an `ISSUE:` / `SOLUTION:` / `LIMITATION:` / `REFERENCE:` header, the reference listing the error-report and ticket links), the external source a block mirrors (the sibling repo, package, or spec section it was ported from, with the spec's field names on each item of a positional structure), one real example value for a marker or format, what a config option does and why it is set when its name doesn't say (`// run tests in one worker: they share one recorded network snapshot`), the human-readable value of a large raw-unit literal (`60_000; // 1 min`), and an input→output example on a parsing or derivation method (`// e.g. (in) "limit_32" → (out) 32`). A why-comment states the real reason; when you don't know it, state the rule plainly instead of inventing a justification. Mark deferred work with a `TODO:` that names the trigger and links its ticket (`// TODO: paginate once the list passes 500 rows (<ticket URL>)`). One line where one line covers it, but a multi-step flow lists one step per line rather than a wrapped paragraph: readability beats line count. Leave a blank line after a comment block when the next line is not what it describes. A user-facing "unavailable" message follows the same rule: say what isn't supported, not the mechanism behind it.

## Guards

- **Prove It Before Guarding**: Typical unreachable guards: an optional constructor arg the caller never omits, a null check on a non-nullable value, a re-read of data nothing else mutates, a `catch` on a path that can't throw. Unreachable defensive code is dead weight that misdirects the next reader about where the real risk is.
- **Guard Clauses Over Nesting**: Invert the condition and leave first (`return`, or `continue` in a loop), then write the main path unindented below a blank line — `if (seen.has(item)) { continue; }` then the work, not the work wrapped in `if (!seen.has(item)) { ... }`. Consecutive guard clauses sit together with no blank line between them.
- **Confirmations Default To No**: An interactive prompt that confirms sending a message or writing data defaults to no, so an accidental Enter does nothing.
- **Cheap Check First**: A check that can end the work early (a feature flag, a field already in memory) runs before the query or fetch it would make unnecessary, not after it.

## Structure and naming

- **Extract A Repeated Call Pattern**: When the same call with the same options shows up at several sites (a config namespace read, a router call with fixed flags, a permission check), move it into one named helper or small module and put its why-comment there. Look for an existing utility that already does it before writing a new one.
- **Methods Read As Steps**: A method with distinct steps (a command handler, a framework callback such as middleware or a route closure, a service method) reads as a short list of named calls, one per step. Extract each step into a private function even when it has one caller; only a one-line helper is inlined. The detail lives in the called functions, shaped so the next variant slots in. Number the steps with comments (`// 1. Ask for the parent record`) when at least one step spans several statements; a list of bare one-line calls needs none.
- **Main Case First**: Order sibling branches and variants (route or `switch` cases, fixtures, enum cases) with the main or most-used one first; secondary and edge cases follow.
- **Name Intermediate Values**: Assign a nested expression (a parsed value used as an index, a calculation inside a condition, a ternary passed as an argument) to a descriptively named variable first, so each line does one thing: `const pathname = new URL(url).pathname;` then `files[pathname]`. A single call whose name already says what it returns is used inline when it is used once (`shouldLockAction(eligibility) ? <LockIcon /> : icon`); name a value only when the expression is nested, compound, or repeated.
- **Callback Parameters Are Nouns**: A callback parameter is named for what it holds (`fn (Invoice $invoice) => $invoice->total`), never a single letter.
- **The Verb Says How The Value Is Obtained**: `findX` fetches and may return null, `findXOrFail` fetches or throws, `buildX` assembles a new structure, `makeX` assembles a new scalar such as a string.
- **Don't Repeat The Class's Noun**: A method doesn't repeat the noun of the class or enum it lives on: `Column::Title->isSearchable()`, not `isSearchableColumn()`.
- **Name A Class Or Method For Its Full Subject**: A class or type name carries the full subject and a role noun for what it does (`NetworkSnapshotRecorder`, not `NetworkRecording`), and its file takes the same name. A method whose verb acts on something other than its class names that object (`recordRealResponse()`, not `record()`); a verb that acts on the class itself stays bare (`$invoice->save()`, a controller's `store()`).
- **Merge Helpers Always Called Together**: When two complementary helpers are only ever called as a pair from the same site, make them one function returning both results (`{ available, unavailable }`) instead of two calls the reader has to correlate.
- **Name Reflects Behavior, Not Assumption**: When a method or variable's real behavior doesn't match what its name implies — a qualifier it doesn't actually check, a filter it silently applies that the name doesn't mention, a descriptor that overstates precision (`getLatestX` with no such ordering) — rename it to match the real behavior instead of leaving the mismatch for the next reader to trip over. A function that returns a boolean only answers its question: a write it seems to need (storage, a counter, state) goes in the caller. Name complementary helpers as an antonym pair (`getAvailableX` / `getUnavailableX`), not two unrelated synonyms.
- **Widen The Helper, Not The Callers**: When a shared helper's parameter type forces callers to reshape what they already hold (unwrap a model to its ID, reindex a map into a list), widen the helper to accept that form too, so existing call sites stay untouched and the diff stays in one place.
- **Copy Stable Keys, Not Mutable Labels**: A denormalized copy (search index, cache) stores a related record's ID, not its display name; resolve the name at read time, since the name can change outside the copy's lifecycle. A record of something that happened (invoice, issued document, audit entry) is the exception: it keeps its own copy of the labels it showed.

## Formatting

- **Siblings Share One Shape**: Sibling entries of one literal are formatted alike: once one breaks across lines, all do.
- **Break A Long Ternary Before `?` And `:`**: A ternary that doesn't fit on one line puts each branch on its own line, led by its `?` or `:`.
- **Blank Line Before `return`**: A `return` that follows other statements has one blank line above it.
- **One Newline At End Of File**: Every file you create or edit ends with exactly one line break, including a file that lacked one before your edit; otherwise the diff shows "no newline at end of file" on your lines.

## Where logic lives

- **Validate Configuration On Save**: Configuration a user edits is validated when it is saved or published; the code that consumes it later trusts it instead of re-checking on every run.
- **Mark A Side Effect Where It Happens**: The timestamp or flag that records a side effect (`sent_at`) is set right beside the call that performs it, not in a later step.
- **Reuse The Variant Already In Use**: When a module already uses one algorithm, library or format for a job (a hash function, a date library, an ID format), new code uses the same one; a second variant needs a stated reason.
- **Read Fixed Values From The Loaded Schema**: A fixed value that a schema or spec file the code already loads carries (a context URL, an allowed-values list) is read from that file, not hardcoded as a second copy.
- **API Errors Carry A Code**: An API error response includes a stable error code or type string alongside the HTTP status and message, so integrators can branch on the exact cause.
- **A Feature Flag Gates Availability Only**: A flag decides whether an option exists. Behaviour that differs per record is a setting on that record, never implied by the flag being on.

## Review gate

Applies when the language skill has a `references/checklist.md`. Changed code is not done until it has passed these steps, in order, before presenting or committing. For a small diff, skip the workers and do steps 2 and 3 yourself in-session.

1. **Tooling.** Run the repo's formatter, linter and tests. No model reviews what tooling enforces.
2. **Bug review.** Send the diff to Codex for a review of bugs and missed requirements, per the global Codex rules; when Codex is out of usage, use a Claude Opus reviewer. Fix its findings yourself: they need the task's context.
3. **Style pass.** `git add` the changed paths, then hand a cheap execution worker (Codex luna or Claude Sonnet, the latest of either) the staged diff and the language skill's core rules and checklist. Its brief:
    - Edit only lines the diff changed.
    - Apply a fix only when it leaves every signature, file, query and output as it was. Otherwise leave the code and report the violation with its file, line and rule.
4. **Read the worker's diff.** `git diff` now shows only the worker's edits. Rerun the linter and tests, then fix the violations it reported. In a test file, a green run doesn't clear the edit: confirm each changed assertion and mock still checks what it checked before.

## Dependencies and swaps

- **Fix Dependencies At The Root**: For a vulnerable or stale dependency, first check whether the code still uses it and remove it if not; otherwise bump the direct dependency. A package-manager override or pin is a last resort for a transitive dependency the direct one can't move yet, carries a comment naming when it can go, and is deleted once that reason is gone.
- **A Swap Keeps The Output**: When replacing a library or implementation behind an existing output (a PDF renderer, an export format, a serializer), the result must match the old one visually and structurally. A cosmetic difference is a defect to fix before presenting the work, not a note to leave in the PR.
