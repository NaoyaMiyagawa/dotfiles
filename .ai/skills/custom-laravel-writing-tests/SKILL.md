---
name: custom-laravel-writing-tests
description: Laravel/Pest testing conventions (TDD, structure, fixtures, controller boundaries). Use when writing or updating Pest tests, factories, datasets, or mocks.
---

Write tests test-first in the project's Pest shape. Hold the core structural rules below in mind while writing; formatting, assertion, factory, and dataset style details live in [references/checklist.md](references/checklist.md) and are enforced by the review gate.

Run tests per `custom-php-sail` (`~/dotfiles/.ai/skills/custom-php-sail/SKILL.md`) — Sail only, minimal containers, no `--parallel` locally.

## Workflow (t_wada TDD)

1. Write a test list.
2. Pick one case and write a failing test.
3. Implement the minimum code to pass all tests.
4. Refactor.
5. Repeat until the test list is empty.

Before refactoring an uncovered path, write a **characterisation test** pinning current observable behaviour, confirm it's green, then refactor while keeping it green.

## Core rules

1. **The test is the source of truth.** When an existing test encodes intended behaviour, fix the implementation — edit a test only when the spec changed.
2. **Leave pre-existing passing tests alone.** Apply conventions only to cases you add or change; restyling unrelated passing tests buries the diff.
3. **Don't leak tests into production code.** No test-only constructor args, setters, or flags (`$overrides`). Use framework fakes (`Http::fake()`, `Storage::fake()`, `Queue::fake()`) and container bindings.
4. **Only create fixtures the code under test reads.** Pass a plain scalar id (`verifier_id => 1`) when the logic doesn't read the related record. For a "belongs to someone else" case, the default factory already yields a foreign record — assert the precondition (`expect($invoice->organization->is($this->user->organization))->toBeFalse();`) instead of building a second tenant graph.
5. **Right-size the suite and assert what the case names.** Fold one-line variants into a neighbouring case or dataset; scope assertions to the case's stated purpose (no incidental structural checks that make tests brittle).
6. **One test file per production class, named verbatim after it.** `RunManualPostIssuanceActionJob` → `RunManualPostIssuanceActionJobTest.php`. Enter through the class under test: HTTP cases go in `{Controller}Test.php` even when logic lives in a service. Mirror the class's directory (`Feature/Controllers/…`); multi-route/multi-class flows go in `Feature/Integration/`.
7. **`describe('<method-name>')` matches the subject's public method — one `describe` per method.** Merge new cases into the existing block. If one case needs a real dependency that `beforeEach` fakes, swap the fake off inside that case. Name cases without leading "it" (`it('creates the record')`), and double-quote names with apostrophes.
8. **Group cases in request-flow order.** Inside a method's `describe`: `happy paths` → `unhappy paths - validations` → `unhappy paths` → `authorization` → `edge cases`. Major flows above minor; distinct service flows get nested `describe` blocks.
9. **`beforeEach` shape.** Import and call Pest Laravel functions bare (`actingAs()`, `from()`), not via `$this->`. Create local variables first, then assign to `$this` properties (static literals exempt). Name the shared user by role (`$superAdmin`, `$reviewer`). Put shared `Queue`/`Event`/`Mail` fakes here. Resolve the subject via `app(Xxx::class)->method()` at each call site (not cached on `$this`). Set config with `config()->set(...)` and assert against raw literals (or production constants like `Controller::PAGE_SIZE`).
10. **AAA markers & request/assertion shape.** Use `// Arrange`, `// Act`, `// Assert` (`// Act & Assert` for compact tests), build URLs with `route()`, chain one `assert*()` per line, and assert full validation message maps against resolved English strings (not `__('key')`). Formatting and helper details are in [references/checklist.md](references/checklist.md).
11. **Controller tests stay thin.** When a controller delegates to an Action/Service/Job with its own test, mock the delegate and cover only: one success case (args passed), validation cases, one rejection case (exception→response mapping), and authorization. Domain branching and side effects belong in the delegate's test.
12. **Add a factory in the same PR as a new Eloquent model** (`HasFactory` + required columns).

## Review gate (mandatory)

Changed test code is not done until it passes the review gate in `custom-general-coding` against the Core rules above and [references/checklist.md](references/checklist.md) (run alongside `custom-laravel-coding` when production PHP also changed).
