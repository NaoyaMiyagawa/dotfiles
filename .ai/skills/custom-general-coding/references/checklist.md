# General coding checklist — style, naming, and comments

The review gate in `../SKILL.md` enforces this list alongside the language checklist. Every rule here is style or comment hygiene: fixing it leaves signatures, files, queries, and outputs unchanged.

## Comments

- **Comments Carry Only What Code Can't Say**: Delete comments that restate the code. Previous/deleted implementations belong in git, not comments or decision notes. Don't repeat in a decision note what a code-site comment already states.
- **Keep what a reader can't derive**:
  - Why a line exists (`// for idempotency`) — state the real reason; if unknown, state the rule plainly rather than inventing a justification.
  - What a non-obvious block does to data (state the effect, not just when it runs, in one line above it or as a private method name: `// drop validFrom from required until issuance fills it`).
  - Why a workaround exists and when it can go (workaround module opens with `ISSUE:` / `SOLUTION:` / `LIMITATION:` / `REFERENCE:` listing error-report/ticket links).
  - External source a block mirrors (sibling repo, package, or spec section, with spec field names on positional structures).
  - One real example value for a marker/format, or input→output example on a parsing/derivation method (`// e.g. (in) "limit_32" → (out) 32`).
  - Config options whose names don't explain why they're set (`// run tests in one worker: they share one recorded network snapshot`).
  - Human-readable value of a large raw-unit literal (`60_000; // 1 min`).
  - Deferred work: `TODO:` naming the trigger and linking its ticket (`// TODO: paginate once >500 rows (<ticket URL>)`).
- One line where one line covers it; multi-step flows list one step per line rather than a wrapped paragraph. Leave a blank line after a comment block when the next line isn't what it describes. User-facing "unavailable" messages state what isn't supported, not the mechanism behind it.

## Naming

- **Name Intermediate Values**: Assign nested, compound, or repeated expressions to a descriptively named variable first (`const pathname = new URL(url).pathname;`). Inline a single-use call whose name already says what it returns.
- **Callback Parameters Are Nouns**: Name for what it holds (`fn (Invoice $invoice) => ...`), never a single letter.
- **The Verb Says How The Value Is Obtained**: `findX` fetches or returns null, `findXOrFail` fetches or throws, `buildX` assembles a structure, `makeX` assembles a scalar.
- **Don't Repeat The Class's Noun**: `Column::Title->isSearchable()`, not `isSearchableColumn()`.
- **Name A Class Or Method For Its Full Subject**: Class/type names carry full subject + role noun (`NetworkSnapshotRecorder`, not `NetworkRecording`), matching the filename. Methods acting on something other than their class name that object (`recordRealResponse()`, not `record()`); methods acting on the class itself stay bare (`$invoice->save()`, `store()`).
- **Name Reflects Behavior, Not Assumption**: Rename methods/variables whose names overstate or hide filters/ordering (`getLatestX` without ordering). Boolean-returning functions only answer their question (no hidden writes). Name complementary helpers as an antonym pair (`getAvailableX` / `getUnavailableX`).
- **Main Case First**: Order sibling branches, routes, switch/enum cases, and fixtures with the main/most-used case first.

## Formatting

- **Siblings Share One Shape**: Once one sibling entry of a literal breaks across lines, all do.
- **Break A Long Ternary Before `?` And `:`**: Put each branch on its own line, led by `?` or `:`.
- **Blank Line Before `return`**: One blank line above a `return` that follows other statements.
- **One Newline At End Of File**: Every created/edited file ends with exactly one newline (fix missing trailing newlines on touched files).
