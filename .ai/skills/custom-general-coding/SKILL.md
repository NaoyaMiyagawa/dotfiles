---
name: custom-general-coding
description: Language-agnostic coding rules — which comments to keep, guards, naming, paired helpers, denormalized copies, dependency fixes, and library swaps. Use when writing, refactoring, or reviewing code in any language, alongside the language skill when one exists.
---

# General Coding Rules

## Comments

- **Comments Carry Only What Code Can't Say**: Delete a comment that restates the code. A previous or deleted implementation belongs in git — not in a comment, and not in a decision note or doc either. A decision note doesn't repeat a why that a comment at the code site already states. Keep what a reader can't derive: why a line exists (`// for idempotency`), what a non-obvious block does to the data — say the effect, not just when it runs, in one line above it or as the name of a private method it moves into (`// drop validFrom from required until issuance fills it`), why a workaround is there and when it can go (a workaround module opens with an `ISSUE:` / `SOLUTION:` / `LIMITATION:` / `REFERENCE:` header, the reference listing the error-report and ticket links), the external source a block mirrors (the sibling repo, package, or spec section it was ported from, with the spec's field names on each item of a positional structure), one real example value for a marker or format, the human-readable value of a large raw-unit literal (`60_000; // 1 min`), and an input→output example on a parsing or derivation method (`// e.g. (in) "limit_32" → (out) 32`). A why-comment states the real reason; when you don't know it, state the rule plainly instead of inventing a justification. Mark a deliberately temporary state "for now" and name the risk accepted. One line where one line covers it, but a multi-step flow lists one step per line rather than a wrapped paragraph: readability beats line count. Leave a blank line after a comment block when the next line is not what it describes. A user-facing "unavailable" message follows the same rule: say what isn't supported, not the mechanism behind it.

## Guards

- **Prove It Before Guarding**: Typical unreachable guards: an optional constructor arg the caller never omits, a null check on a non-nullable value, a re-read of data nothing else mutates, a `catch` on a path that can't throw. Unreachable defensive code is dead weight that misdirects the next reader about where the real risk is.

## Structure and naming

- **Merge Helpers Always Called Together**: When two complementary helpers are only ever called as a pair from the same site, make them one function returning both results (`{ available, unavailable }`) instead of two calls the reader has to correlate.
- **Name Reflects Behavior, Not Assumption**: When a method or variable's real behavior doesn't match what its name implies — a qualifier it doesn't actually check, a filter it silently applies that the name doesn't mention, a descriptor that overstates precision (`getLatestX` with no such ordering) — rename it to match the real behavior instead of leaving the mismatch for the next reader to trip over. A function that returns a boolean only answers its question: a write it seems to need (storage, a counter, state) goes in the caller. Name complementary helpers as an antonym pair (`getAvailableX` / `getUnavailableX`), not two unrelated synonyms.
- **Copy Stable Keys, Not Mutable Labels**: A denormalized copy (search index, snapshot, cache) stores a related record's ID, not its display name; resolve the name at read time, since the name can change outside the copy's lifecycle.

## Dependencies and swaps

- **Fix Dependencies At The Root**: For a vulnerable or stale dependency, first check whether the code still uses it and remove it if not; otherwise bump the direct dependency. A package-manager override or pin is a last resort for a transitive dependency the direct one can't move yet, carries a comment naming when it can go, and is deleted once that reason is gone.
- **A Swap Keeps The Output**: When replacing a library or implementation behind an existing output (a PDF renderer, an export format, a serializer), the result must match the old one visually and structurally. A cosmetic difference is a defect to fix before presenting the work, not a note to leave in the PR.
