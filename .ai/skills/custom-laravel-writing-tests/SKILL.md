---
name: custom-laravel-writing-tests
description: Applies Laravel and Pest testing conventions, including TDD workflow and test structure rules. Use when writing or updating Pest tests, feature tests, factories, datasets, beforeEach setup, or assertion patterns.
---

## Core Testing Workflow

Follow t_wada TDD:

1. Write a test list.
2. Pick one case and write a failing test.
3. Implement the minimum code to pass all tests.
4. Refactor.
5. Repeat until test list is empty.

## Test as the source of truth

When an existing test encodes the intended behaviour, change the implementation to satisfy the test — don't rewrite the test to match new (possibly wrong) implementation behaviour. Only edit a test when the specification itself changed.

## Leave pre-existing passing tests alone

Apply the current conventions (AAA, naming, dataset style, assertion rules) to the test cases you add or change — not to unrelated cases that already pass. Don't restyle, rename, or rewrite pre-existing tests to match today's conventions as part of a feature/fix PR: that churn buries the real diff in review and risks breaking a working guard. Bring an old test in line only when its behaviour is genuinely part of the change.

## One test file per production file

Keep a 1:1 mapping between a production file and its test file. When a change leaves one class's tests split across two test files (e.g. a feature's cases carved into a separate file), merge them into the single test file that mirrors the production file rather than leaving a class's tests scattered.

## Refactoring untested code

Before refactoring a code path that has no direct test coverage, first write a **characterisation test** that pins the current observable behaviour and get it green against the _existing_ implementation. Then refactor while keeping it green. This proves the change is behaviour-preserving rather than asserting it after the fact.

## Don't leak tests into production code

Don't add constructor parameters, setters, or config flags to production classes whose only purpose is to make them testable (e.g. an `$overrides` array a test passes in). Use the framework's fakes and the container instead — `Http::fake()`, `Storage::fake()`, `Queue::fake()`, or binding a test double in the container. Production signatures should reflect production needs only.

## Only create fixtures the code under test depends on

When the logic under test doesn't read a related record, don't create one to satisfy a foreign key — pass a plain scalar id instead (`verifier_id => 1`). Creating unused rows blurs the test's boundary and slows it down; reach for a factory only when the behaviour actually depends on that record existing.

The same applies to a "belongs to someone else" case: the default factory already yields a foreign record, so don't build the other tenant's whole graph. One sanity `expect()` states the precondition.

```php
// Arrange
$invoice = Invoice::factory()->createOne();
expect($invoice->organization->is($this->user->organization))->toBeFalse();

// Act & Assert
post(route('invoices.resend', ['invoice' => $invoice->id]))
    ->assertNotFound();
```

## Freeze time to assert a timestamp

When the code under test stamps a datetime, call `freezeTime()` in Arrange and assert the exact value against `now()` — `expect($document->issued_at->toDateTimeString())->toBe(now()->toDateTimeString())`. A `not->toBeNull()` on a timestamp proves the column was touched, not that it was set to the right moment.

## Right-size the suite

Don't add a case an existing case already covers, and don't open a test file for one trivial case. Fold a one-line variant into the neighbouring case instead of a new `it()`. A dev-only or simulation class keeps only the cases that guard its important behaviour. Several cases that each check one header or one payload field usually collapse into one.

## Assert the behaviour the test names

Scope assertions to the case's stated purpose. When the point is "the response comes back without error", asserting a successful response is enough — don't pile on incidental structural checks (a specific JSON path, a field-level `missing()` on some nested key) that aren't what the test is proving. Extra narrow assertions read as coverage but just make the test brittle against unrelated shape changes.

## Pest Rules

1. Write tests in Pest style.
2. Import Pest Laravel functions when used:
    - `use function Pest\Laravel\actingAs;`
    - `use function Pest\Laravel\mock;`
3. `describe('<method-name>')` must match the subject public method — one `describe` per method; merge cases into the existing block instead of duplicating a method's `describe`.
4. Name cases without a leading "it": `it('creates the record')`, not `it('it creates the record')`.

## Running tests

Follow the `custom-php-running-test` skill (`~/dotfiles/.ai/skills/custom-php-running-test/SKILL.md`) — Sail only, minimal containers, no `--parallel` locally.

## Coding standard

### beforeEach

1. Create local variables first, then assign to `$this` properties.
2. Exception: static literal values that do not come from factories.
3. Set fakes in `beforeEach` (`Event::fake([...])`, `Storage::fake(...)`). When the method under test dispatches a job, event, or mail, fake `Queue`/`Event`/`Mail` in `beforeEach` for every case in the block regardless of case type — the thing being tested is always whether it dispatches, so the fake belongs in setup, not per-case.

Example:

```php
beforeEach(function () {
  $user = User::factory()->createOne();
  actingAs($user);

  $this->user = $user;
});

describe('{method name}', function () {
  beforeEach(function () {
    // Set fakes e.g. Queue::fake([]); Event::fake([]);
  });

  it('...', function () {

  });
});
```

4. Resolve the class under test with `app(Xxx::class)->method()` at each call site — don't cache it in a `$this->` property. A stored property loses IDE completion on the lines that use it.
5. When the code under test reads config, set the value in `beforeEach` (`config()->set('app.url', 'https://app.example.test')`) and assert against the raw literal — don't rebuild the expectation by reading config back or composing it with helpers.
6. Reuse a constant the production class already declares (`Controller::PAGE_SIZE`) instead of repeating its literal in the test.

### Dataset

1. Use `->with()` when cases can be combined.
2. Keep multiline function arguments for dataset-driven tests.
3. For multiple parameters in dataset rows, use named variables in values for readability.

```php
it('xxx', function (
  XxxStatus $status, // always add line break even if it's only 1 arg for readability
) {

})->with([
  '{case name}' => [
    $status = XxxStatus::Pending, // use variable so that it's easier to match with args
  ]
]);
```

### Validation tests

- Consolidate validation cases into a single dataset, including uniqueness / "already exists" cases — they are the same kind of assertion.
- For per-case arrange logic, put a closure column in the dataset row instead of branching with `match`/`switch` on the case label inside the test body.
- Closure columns do not need identical signatures just because they share a dataset column. Match each closure to how the test invokes it: too many arguments are ignored by user-defined closures, but missing required arguments still throw `ArgumentCountError`.
- When a dataset row needs to read `beforeEach` state (`$this->...`), wrap the **entire row** in a closure that returns the array — `$this` is bound to the test instance only inside that closure, not inside per-column closures. Prefer this over duplicating literal values across rows.

    ```php
    // Good — $this available across the whole row
    'file is not an image' => function () {
        return [
            UploadedFile::fake()->createWithContent(
                'not_a_dog.xls',
                file_get_contents(storage_path($this->invalidImage)),
            ),
            'The file field must be an image.',
        ];
    },

    // Bad — $this is not bound inside a per-column closure
    'file is not an image' => [
        fn () => UploadedFile::fake()->createWithContent(
            'not_a_dog.xls',
            file_get_contents(storage_path($this->invalidImage)), // undefined
        ),
        'The file field must be an image.',
    ],
    ```

    ```php
    it('rejects invalid payloads', function (
      Closure $arrange,
      array $payload,
      array $errors,
    ) {
      $arrange();
      post(route('...'), $payload)
          ->assertInvalid($errors);
    })->with([
      'file is required' => [
        $arrange = fn () => null,
        $payload = [],
        $errors = ['file' => 'The file field is required.'],
      ],
      'name already taken' => [
        $arrange = fn () => Item::factory()->createOne(),
        $payload = ['name' => 'dup'],
        $errors = ['name' => 'The name has already been taken.'],
      ],
    ]);
    ```

### Factory

- **Add a factory class in the same PR as a new Eloquent model.** Without one, tests reach for raw `Model::create([...])` or `DB::insert(...)` and the convention drifts; later contributors then have nothing to copy from. Wire it via the `HasFactory` trait and include at least the columns the model marks as required.
- **Derive a factory default with the same rule production uses.** When a column's value is computed from another field (e.g. a type/key derived from a path or parent), the factory must apply the _real_ derivation, not a convenient shortcut that happens to pass for simple cases. A factory default that diverges from production logic seeds inconsistent data and lets bugs slip past green tests.
- **States that persist related records go in `afterCreating()`, not `afterMaking()`.** A state should keep `Model::factory()->someState()->make()` database-free: only assign explicitly-provided associations during `make()`/`state()`, and defer creating any default related record to `afterCreating()`. Building a related record in `afterMaking()` makes `make()` silently hit the database, which surprises callers that expected an unsaved instance.
- A state method returns `$this->state(fn () => [...])` — no return type on the closure. The per-key lazy form `'key' => fn () => ...` belongs in `definition()` only.
- Prefer factory state methods when available to reduce hardcoding keys.
  e.g. `withStatus(XxxStatus $status)` when having `status` column.
  If there is no existing state method for a column, you can add it.
  Prefer this order of state methods in factory class.
  e.g.
    - definitions() ... factory's default method
      // relationships
    - forXxx($modelOrFactory) ... only when we need to specify relationship name with ->for(). Never pass a literal relationship-key string at the call site (`->for($model, 'reviewer')`) — wrap it in a `forXxx()` state method instead, adding one if it doesn't exist yet.
    - hasXxx($modelOrFactory) ... only when we need to specify relationship name with ->has().
      // states
    - xxx() ... higher level api for setting specific data for one or more columns (e.g. `pending()`)
    - withXxx($value) ... low level api for setting data for specific columns.
- Use `->forEachSequence()` when all patterns must be covered.
- Use `->createOne()` / `->createMany()` for better return types.
- Prefer `::factory(x)` over `->count(x)` when creating more than one record.
- Extract common lines when calling multiple same factories and they are similar.
  e.g.

    ```php
    // Bad
    WorkflowReviewSubmission::factory()
        ->for($this->actionRun)
        ->for($this->reviewers[1], 'reviewer')
        ->withStatus(WorkflowReviewSubmissionStatus::InProgress)
        ->createOne();
    WorkflowReviewSubmission::factory()
        ->for($this->actionRun)
        ->for($this->reviewers[2], 'reviewer')
        ->completed()
        ->createOne();

    // Good
    $reviewSubmissionFactory = WorkflowReviewSubmission::factory()->for($this->actionRun);
    $reviewSubmissionFactory
        ->forReviewer($reviewers[1])
        ->withStatus(WorkflowReviewSubmissionStatus::InProgress)
    // ...
    ```

### AAA Comments

Use AAA comments:

```php
// Arrange
...
// Act
...
// Assert
...
```

Use `// Act & Assert` for compact tests only. Add the markers to every case you write, even when the surrounding cases in an older file lack them.

A bare `//` comment in a test is reserved for the three AAA markers only. Every other comment inside a test body — a sub-step under a section, a note on a line — carries the `- ` prefix. So when one AAA section contains multiple distinct sub-steps (e.g. several setup steps under `// Arrange`), prefix each with `- ` so the structure is scannable at a glance:

```php
// Arrange
// - create the workflow run
// - upload the failing document
...
```

### Feature Test Pattern

1. Use `route('...')` to build request URLs.
2. Prefer combining request and assertion fluently when clear. When the request has a body, pass the payload as a multi-line array literal as the call's second argument (`postJson(route(...), [ 'xxx' => ..., ])`) and chain the assertions directly off it — don't hoist the payload into a separate variable or cram it onto one line. One chained call per line: `withToken()`, the request, and each `assertXxx()` each get their own line. Keep the `route()` call itself on one line unless it carries more than one query parameter.
3. Reach for the dedicated helper before hand-rolling its equivalent: `withToken()` over a hand-built `Authorization` header, `assertInvalid()` over `assertSessionHasErrors()`, `assertRedirectBack()` over `assertRedirect(route(...))` when the redirect is back, `createOneQuietly()` over building a model by hand, and the model class in `assertDatabaseHas(Model::class, ...)` over the table name.

Example:

```php
// [When only assert chains covers test targets]
// Act & Assert
post(route(...))
  ->assertValid()
  ->assertRedirect();

// [When you need to use response value]
// Act & Assert
$response = post(route(...))
  ->assertValid()
  ->...

$data = $response->...;
assert($data)->...
```

4. Use `describe()` blocks to group cases in request-flow order: happy paths first, then validation failures (they reject before business logic runs), then other unhappy paths, then authorization, then edge cases. Major behaviour sits above minor: a secondary feature of an endpoint gets its own `describe` at the bottom, and cases follow the branch order of the production code they exercise.

```php
describe('{method name}', function () {
  describe('happy paths', function () {
    // Test successful cases
  });

  describe('unhappy paths - validations', function () {
    // Test validation error cases
  });

  describe('unhappy paths', function () {
    // Test other error cases
    // e.g.)
      it('returns 404 for workflow from another org', function () {
        // ...
      });
  });

  describe('authorization', function () {
    // Test policy / middleware logic
      // e.g.)
      it('returns 403 for workflow from another org group', function () {
        // ...
      });
  });

  describe('edge cases', function () {
    // Test the rare shapes — put this block last, under the major cases
  });
});
```

### Action/Service class test

- If there are certain flows in business logic, use `describe` block to separate them.
  e.g.

    ```php
    describe('entryFlow', function () {
    });

    describe('completionFlow', function () {
    });
    ```

### Mock

Always use mock from Pest. Prefer to chain mock and method calls. Have variable when defining mock in beforeEach() or when having multiple `->shouldReceive()` call.

```php
use function Pest\Laravel\mock;

mock(Xxx::class)
    ->shouldReceive('')
    ->once()
    ...
```

### Assertions

- To assert a record persisted, prefer `$model->refresh()` (reloads from DB) over `expect($model)->toBeInstanceOf(...)` + `expect($model->exists)->toBeTrue()` — the refresh both confirms persistence and surfaces the stored values for further assertions.
- One `expect()` per subject: chain every matcher for that subject off it, and start a new `expect()` line when the subject changes. Never `->and()`.

    ```php
    expect($signer->request['Message'])
        ->toBe($digest)
        ->toHaveLength(32)
        ->not->toBe(hash('sha256', $digest, binary: true));

    expect($signer->request['KeyId'])->toBe($keyId);
    ```

- `toBe` for scalars and enums; `toEqual` for arrays and objects, where key order and instance identity aren't part of the contract (JSON columns round-tripped through the DB reorder keys).
- Use `foreach` over `assert(x)->each()` for cleanliness.
- For validation failures, always assert with the full expected message map, not the field-only form. Pass the expected message via a dataset column so each case documents its own failure.

    ```php
    // Good
    $response->assertInvalid(['file' => 'The file field is required.']);

    // Bad — field-only or partial match
    $response->assertInvalid(['file']);
    ```

- Assert the resolved, human-readable string — never a translation key or `__('key')`. Asserting the key (or comparing against the same translation call the code uses) can pass even when the translation is missing or wrong, because both sides resolve identically or the key matches its own unresolved fallback. Spell out the literal expected sentence so a broken/missing translation fails the test.

    ```php
    // Good — a missing translation breaks this
    expect($notification->subject)->toBe('Your DNS verification failed.');

    // Bad — passes even if the translation key resolves to nothing
    expect($notification->subject)->toBe('settings::messages.dns_failed');
    expect($notification->subject)->toBe(__('settings::messages.dns_failed'));
    ```

- **Assert datetime values by canonical string, not object instance.** Compare via `->toDateTimeString()` (or a formatted/ISO string) instead of `toBe`/`toEqual` against another datetime object. A mutable vs immutable date class mismatch (e.g. after adding an immutable-datetime cast) fails an object comparison even when the instant is identical; the stringified form sidesteps the class mismatch and still pins the value.

    ```php
    // Good — survives a Carbon vs CarbonImmutable cast change
    expect($model->verified_at->toDateTimeString())->toBe($expected->toDateTimeString());

    // Bad — breaks on class mismatch even when the instant matches
    expect($model->verified_at)->toEqual($expected);
    ```

- **Scope deep assertion paths with a `has()` callback instead of repeating the full dotted key.** Once a chain of `->where('a.b.c.d.…')` calls shares a long prefix, the prefix drowns out the value being asserted. Nest a callback so each level is named once and the leaf assertions read as the shape they describe.

    ```php
    // Good — prefix named once per level
    ->has('editor.version', fn (AssertableJson $version) => $version
        ->where('version', 1)
        ->where('name', 'Course Completion')
        ->etc())

    // Bad — the prefix is most of every line
    ->where('editor.version.version', 1)
    ->where('editor.version.name', 'Course Completion')
    ```

- Add a line break when test target entity changes.
  e.g.)

    ```php
    expect($submission->status)->toBe(WorkflowReviewSubmissionStatus::Pending);
    expect($submission->completed_at)->toBeNull();

    expect($submission->decisions->count())->toBe(count(xxx));
    foreach ($submission->decisions as $decision) {
      expect($decision->...)...;
    }
    ```

### Test file naming

Every production class under test gets its **own** test file mirroring its name — don't append a new class's cases to a collaborator's existing test file just because the flow passes through it (e.g. a job's cases belong in `{Job}Test.php`, not in the controller test that dispatches it).

Test file name must mirror the production class name verbatim, including suffixes like `Job`, `Service`, `Action`, `Controller`.

- `RunManualPostIssuanceActionJob` → `RunManualPostIssuanceActionJobTest.php` (not `RunManualPostIssuanceActionTest.php`)
- `MPIADocumentsController` → `MPIADocumentsControllerTest.php`

### Test directory structure

A test that exercises a single class/route mirrors that class's location (e.g. `Feature/Controllers/…`). A test that spans multiple routes or classes — an end-to-end flow — belongs under the repo's integration directory (`Feature/Integration/`), not filed under any one of the classes it touches. Follow the repo's established structure rather than inventing a new location.

### Controller test scope

When a controller delegates to an Action / Service / Job / Executor class that has its own dedicated test, keep controller tests thin. Mock the delegated class and assert on the call boundary; do **not** re-cover its domain logic.

A controller test should cover only:

1. **One success case** — verifies the controller passes the right args to the action class (mock `->shouldReceive(...)` with expected args).
2. **Validation cases** — request validation rules that live in the controller / FormRequest.
3. **One rejection case** — verifies the controller catches the action's exception and returns the expected response. No need to enumerate every exception message; that belongs in the action's test.
4. **Authorization cases** — policy / middleware behavior owned by the controller layer.

Domain branching, error variants, and side-effects belong in the Action / Service / Job test, not duplicated in the controller test.

### Event listener test

For an event-listener class, add one case between `beforeEach()` and the `handle()`-focused cases that asserts the listener is actually registered for its event (`Event::assertListening(SomeEvent::class, SomeListener::class)`). The remaining cases can then call `->handle(...)` directly instead of firing the real event, which would also trigger unrelated listeners.

### Regression tests

When adding a test to guard against a specific 500/error you just fixed, assert only the success contract (e.g. `assertOk()` / page renders) on the route that previously broke. Don't over-specify by enumerating `->missing(...)` checks for fields the PR removes or by asserting the absence of every offending shape — those add maintenance cost without strengthening the regression guarantee.

### Contract-drift tests

When a test guards a method whose whole purpose is pinning an external-facing shape (e.g. an enum's `toApiPayload()`), mark it with a `// Test cases to detect drift in api payload` comment above the cases — it tells the next reader why the test exists without them having to infer it from the assertions.

### Test target exclusion

Don't write tests that exercise framework or library behaviour rather than logic you own — e.g. asserting that a config override flows through the framework's plumbing. If the test would still pass with your own code deleted and only the framework left, it isn't testing anything you wrote.

No need to write tests for the following classes:

- Resource
- DTO
- Event
- Policy — the controller tests' `authorization` block covers the policy logic; a separate policy test only earns its place when controller tests mock the policy or assert just that it is wired.
