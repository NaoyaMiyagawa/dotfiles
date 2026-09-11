---
name: custom-laravel-writing-tests
description: Applies Laravel and Pest testing conventions, including TDD workflow and test structure rules. Use when writing or updating Pest tests, feature tests, factories, datasets, beforeEach setup, mocks, or assertion patterns.
---

Write tests test-first and in the project's Pest shape. The core rules below are what to hold in mind while writing. The long tail — factories, datasets, mocks, assertion idioms, regression and listener cases — lives in [references/checklist.md](references/checklist.md); read the section you are about to touch, and let the review gate enforce the rest.

Run tests per the `custom-php-running-test` skill (`~/dotfiles/.ai/skills/custom-php-running-test/SKILL.md`) — Sail only, minimal containers, no `--parallel` locally.

## Workflow (t_wada TDD)

1. Write a test list.
2. Pick one case and write a failing test.
3. Implement the minimum code to pass all tests.
4. Refactor.
5. Repeat until the test list is empty.

Before refactoring a code path with no direct coverage, first write a **characterisation test** that pins the current observable behaviour and is green against the existing implementation, then refactor while keeping it green.

## Core rules

1. **The test is the source of truth.** When an existing test encodes the intended behaviour, change the implementation to satisfy it — don't rewrite the test to match new (possibly wrong) behaviour. Edit a test only when the specification itself changed.
2. **Leave pre-existing passing tests alone.** Apply today's conventions to the cases you add or change, not to unrelated cases that already pass; restyling old tests buries the real diff and risks breaking a working guard. Bring an old test in line only when its behaviour is part of the change.
3. **Don't leak tests into production code.** No constructor parameters, setters, or config flags whose only purpose is testability (an `$overrides` array a test passes in). Use the framework's fakes and the container — `Http::fake()`, `Storage::fake()`, `Queue::fake()`, a test double bound in the container.
4. **Only create fixtures the code under test reads.** When the logic doesn't read a related record, pass a plain scalar id (`verifier_id => 1`) instead of a factory row. For a "belongs to someone else" case, the default factory already yields a foreign record — don't build the other tenant's graph; one sanity `expect()` states the precondition:

    ```php
    // Arrange
    $invoice = Invoice::factory()->createOne();
    expect($invoice->organization->is($this->user->organization))->toBeFalse();

    // Act & Assert
    post(route('invoices.resend', ['invoice' => $invoice->id]))
        ->assertNotFound();
    ```

5. **Right-size the suite and assert what the case names.** Don't add a case an existing case covers; fold a one-line variant into the neighbouring case rather than a new `it()`; several cases that each check one header or field usually collapse into one. Scope assertions to the case's stated purpose — when the point is "responds without error", `assertOk()` is enough; incidental structural checks read as coverage but only make the test brittle.
6. **One test file per production class, named verbatim after it.** `RunManualPostIssuanceActionJob` → `RunManualPostIssuanceActionJobTest.php`, suffix included. The class is the one the test *enters through*: a case that sends an HTTP request belongs in that route's `{Controller}Test.php` even when the behaviour lives in a service the controller calls. Don't append a class's cases to a collaborator's test file; merge a class's cases split across two files back into one. A single-class test mirrors the class's location (`Feature/Controllers/…`); a flow spanning several routes or classes goes under the repo's integration directory (`Feature/Integration/`).
7. **`describe('<method-name>')` matches the subject's public method — one `describe` per method.** Merge new cases into the existing block. When the block's `beforeEach` fakes something one case needs real (`Excel::fake()` vs a rendered download), swap the fake off inside that case instead of opening a sibling `describe`. Name cases without a leading "it" (`it('creates the record')`), and double-quote a name containing an apostrophe — a backslash escape breaks grepping for the failed case later.
8. **Group cases in request-flow order.** Inside a method's `describe`: `happy paths` → `unhappy paths - validations` (they reject before business logic runs) → `unhappy paths` → `authorization` → `edge cases` last. Major behaviour sits above minor: a secondary feature of an endpoint gets its own `describe` at the bottom, and cases follow the branch order of the production code they exercise. An action/service with distinct flows gets one nested `describe` per flow (`entryFlow`, `completionFlow`) inside the method's block.
9. **`beforeEach` shape.** Import the Pest Laravel functions you use (`use function Pest\Laravel\actingAs;`). Create local variables first, then assign them to `$this` properties (static literals that don't come from factories are exempt). When every case acts as the same user, `actingAs()` once here and name the variable by role (`$superAdmin`, `$reviewer`), not `$user`. Fakes go in `beforeEach` — when the method under test dispatches a job, event, or mail, fake `Queue`/`Event`/`Mail` for the whole block, since every case is about whether it dispatches. Resolve the class under test with `app(Xxx::class)->method()` at each call site, not a cached `$this->` property (a stored property loses IDE completion). When the code reads config, `config()->set(...)` here and assert against the raw literal, not a value read back from config. Reuse a constant the production class declares (`Controller::PAGE_SIZE`) instead of repeating its literal.

    ```php
    beforeEach(function () {
        $superAdmin = User::factory()->superAdmin()->createOne();
        actingAs($superAdmin);

        $this->superAdmin = $superAdmin;
    });

    describe('store', function () {
        beforeEach(function () {
            Queue::fake([SendInvoiceJob::class]);
        });

        it('...', function () {
            // ...
        });
    });
    ```

10. **AAA markers in every case you write**, even when the surrounding cases in an older file lack them; `// Act & Assert` only for compact tests. A bare `//` comment in a test body is reserved for the three markers — every other comment (a sub-step under a section, a note on a line) carries the `- ` prefix so the structure scans at a glance:

    ```php
    // Arrange
    // - create the workflow run
    // - upload the failing document
    ```

11. **Feature request shape.** Build URLs with `route('...')`, never a path literal. Pass a request body as a multi-line array literal in the call's second argument and chain the assertions directly off it — don't hoist the payload into a local variable or cram it onto one line (a dataset argument is fine). One chained call per line: `withToken()`, the request, and each `assertXxx()` each get their own line, and the first assertion breaks onto its own line even when it is the only one (`])` then `->assertOk();`). Keep the `route()` call on one line unless it carries more than one route or query parameter. Reach for the dedicated helper before hand-rolling it: `withToken()` over a hand-built `Authorization` header, `assertInvalid()` over `assertSessionHasErrors()`, `assertRedirectBack()` over `assertRedirect(route(...))` when the redirect is back, `createOneQuietly()` over building a model by hand, `assertDatabaseHas(Model::class, ...)` over the table name.

    ```php
    // Act & Assert
    postJson(route('invoices.store'), [
        'number' => 'INV-001',
    ])
        ->assertValid()
        ->assertCreated();
    ```

    When the response value is needed, keep the request chain and assert off the variable:

    ```php
    // Act
    $response = post(route('invoices.store'))
        ->assertValid();

    // Assert
    expect($response->json('data.id'))->toBeInt();
    ```

12. **Assertions.** One `expect()` per subject: chain every matcher for that subject off it and start a new `expect()` when the subject changes — never `->and()`. `toBe` for scalars and enums; `toEqual` for arrays and objects where key order and instance identity aren't part of the contract (JSON columns round-tripped through the DB reorder keys). Assert a validation failure with the full expected message map (`assertInvalid(['file' => 'The file field is required.'])`), never the field-only form. Assert the resolved, human-readable string, never a translation key or `__('key')` — comparing against the same translation call the code uses passes even when the translation is missing.

    ```php
    expect($signer->request['Message'])
        ->toBe($digest)
        ->toHaveLength(32)
        ->not->toBe(hash('sha256', $digest, binary: true));

    expect($signer->request['KeyId'])->toBe($keyId);
    ```

13. **Datasets.** Use `->with()` when cases can be combined; keep the `it()` closure's arguments multi-line even for one argument; in each row, assign the values to variables named like the arguments so rows read against the signature:

    ```php
    it('transitions the status', function (
        XxxStatus $status,
    ) {
        // ...
    })->with([
        'pending' => [
            $status = XxxStatus::Pending,
        ],
    ]);
    ```

14. **Controller tests stay thin.** When a controller delegates to an Action / Service / Job with its own test, mock the delegate and assert on the call boundary — never re-cover its domain logic. A controller test covers only: one success case (right args passed to the delegate), validation cases, one rejection case (the delegate's exception maps to the expected response — not every message), and authorization cases. Domain branching, error variants, and side effects belong in the delegate's test.
15. **Add a factory in the same PR as a new Eloquent model**, wired via `HasFactory`, with at least the columns the model requires — otherwise tests reach for raw `Model::create([...])` and the convention drifts. Factory states, ordering, and call-site chain order are in the checklist.

## Review gate (mandatory)

Changed test code is not done until it has passed a style review. Before presenting or committing, review the test diff — only the diff — against the Core rules above and [references/checklist.md](references/checklist.md). For a non-trivial diff, offload the pass to Codex per the global Codex rules, pointing it at those two files as its checklist; for a small diff, do the pass yourself in-session. Fix the violations, then present. When the same change touches production PHP, this review runs as part of the `custom-laravel-coding` gate.
