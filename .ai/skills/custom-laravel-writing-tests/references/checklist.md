# Pest testing checklist — long tail

The review gate in `../SKILL.md` enforces this list; the core rules live there. When a rule here keeps being violated in practice, promote it into the core (move, don't copy). Mechanical rules destined for lint tooling are mapped in `../../custom-laravel-coding/references/tooling-candidates.md`.

## Time

- When the code under test stamps a datetime, `freezeTime()` in Arrange and assert the exact value against `now()` — `expect($document->issued_at->toDateTimeString())->toBe(now()->toDateTimeString())`. A `not->toBeNull()` on a timestamp proves the column was touched, not that it holds the right moment.

## Datasets and validation tests

- Consolidate validation cases into a single dataset, including uniqueness / "already exists" cases — they are the same kind of assertion. Pass the expected message via a dataset column so each case documents its own failure.
- For per-case arrange logic, put a closure column in the dataset row instead of branching with `match`/`switch` on the case label inside the test body.
- Closure columns need not share a signature just because they share a column. Match each closure to how the test invokes it: extra arguments are ignored by user-defined closures, but a missing required argument throws `ArgumentCountError`.
- When a dataset row needs `beforeEach` state (`$this->...`), wrap the **entire row** in a closure returning the array — `$this` is bound to the test instance only there, not inside a per-column closure. Prefer this over duplicating literal values across rows.

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
        // Arrange
        $arrange();

        // Act & Assert
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

## Factory

- Derive a factory default with the same rule production uses. When a column is computed from another field (a type/key derived from a path or parent), apply the real derivation, not a shortcut that happens to pass for simple cases — a diverging default seeds inconsistent data and lets bugs slip past green tests.
- States that persist related records go in `afterCreating()`, not `afterMaking()`. `Model::factory()->someState()->make()` must stay database-free: assign only explicitly-provided associations during `make()`/`state()` and defer default related records to `afterCreating()`.
- A state method returns `$this->state(fn () => [...])` — no return type on the closure. The per-key lazy form `'key' => fn () => ...` belongs in `definition()` only.
- Prefer factory state methods over hardcoding column keys at the call site (`withStatus(XxxStatus $status)` for a `status` column); add the state when it doesn't exist. Order state methods in the factory class:
    - `definition()`
    - relationships: `forXxx($modelOrFactory)` when the relationship name must be passed to `->for()`; `hasXxx($modelOrFactory)` likewise for `->has()`
    - states: `xxx()` — higher-level API setting one or more columns (`pending()`); `withXxx($value)` — low-level API for one column
- Never pass a literal relationship-key string at the call site (`->for($model, 'reviewer')`) — wrap it in a `forXxx()` state, adding one if missing. Its body is `return $this->for($owner, 'owner');` when the model declares the relationship, not a `state()` closure writing the raw `owner_id` column.
- Use `->forEachSequence()` when every pattern must be covered.
- Use `->createOne()` / `->createMany()` for better return types; prefer `::factory(x)` over `->count(x)` when creating more than one record.
- Order a factory chain at the call site: `count()` (where it must appear, e.g. nested inside `->has()`), then relationship states (`->has(...)`, `->forXxx(...)`), then column states (`->active()`, `->withXxx(...)`), then the `create*()` call.
- Extract the common prefix when several calls to the same factory share it:

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
        ->createOne();
    $reviewSubmissionFactory
        ->forReviewer($reviewers[2])
        ->completed()
        ->createOne();
    ```

## Feature test extras

- A response assertion reused across test files (a downloaded-PDF check, a JSON envelope check) becomes a `TestResponse` macro in `tests/Pest.php` so it chains like the built-ins: `post(...)->assertDownloadedPdf()`, not a standalone helper taking `$response`.

## Mock

Always use `mock()` from Pest (`use function Pest\Laravel\mock;`) and chain the expectations. Hold the mock in a variable only when defining it in `beforeEach()` or when it carries several `->shouldReceive()` calls.

```php
mock(Xxx::class)
    ->shouldReceive('handle')
    ->once()
    ->with($expected);
```

## Assertion extras

- To assert a record persisted, prefer `$model->refresh()` over `expect($model)->toBeInstanceOf(...)` + `expect($model->exists)->toBeTrue()` — the refresh confirms persistence and surfaces the stored values for further assertions.
- Use `foreach` over `expect($x)->each()`.
- Assert datetime values by canonical string, not object instance: compare via `->toDateTimeString()` (or a formatted/ISO string). A mutable vs immutable date class mismatch (after adding an `immutable_datetime` cast) fails an object comparison even when the instant is identical.

    ```php
    // Good — survives a Carbon vs CarbonImmutable cast change
    expect($model->verified_at->toDateTimeString())->toBe($expected->toDateTimeString());

    // Bad — breaks on class mismatch even when the instant matches
    expect($model->verified_at)->toEqual($expected);
    ```

- Scope deep JSON assertion paths with a `has()` callback instead of repeating the full dotted key — once a chain of `->where('a.b.c.d')` shares a long prefix, the prefix drowns the value being asserted. Keep the callback an arrow function even when the chain spans several lines — the exception to the Laravel checklist's arrow-to-closure rule; switch to a classic closure only when the callback needs more than one chained assertion expression.

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

- Add a blank line when the asserted entity changes:

    ```php
    expect($submission->status)->toBe(WorkflowReviewSubmissionStatus::Pending);
    expect($submission->completed_at)->toBeNull();

    expect($submission->decisions->count())->toBe(count($decisions));
    foreach ($submission->decisions as $decision) {
        expect($decision->status)->toBe(DecisionStatus::Pending);
    }
    ```

## Event listener test

Add one case between `beforeEach()` and the `handle()`-focused cases asserting the listener is registered for its event (`Event::assertListening(SomeEvent::class, SomeListener::class)`). The remaining cases then call `->handle(...)` directly instead of firing the real event, which would also trigger unrelated listeners.

## Regression tests

- For a fixed 500/error, assert only the success contract (`assertOk()` / page renders) on the route that broke. Don't over-specify with `->missing(...)` checks for fields the PR removes or by asserting the absence of every offending shape — maintenance cost without a stronger guarantee.
- For a query-count fix (an N+1), assert the count itself — `expectsDatabaseQueryCount(n)` or a `DB::listen()` tally against several records — so the case fails on the unfixed code and stays red if the N+1 returns. A plain `assertOk()` cannot see the extra queries.

## Contract-drift tests

When a test guards a method whose whole purpose is pinning an external-facing shape (an enum's `toApiPayload()`), mark it with `// Test cases to detect drift in api payload` above the cases so the next reader knows why the test exists.

## Test target exclusion

- Don't test framework or library behaviour — e.g. that a config override flows through the framework's plumbing. If the test would still pass with your own code deleted, it tests nothing you wrote.
- No tests for: Resource, DTO, Event. Policy — the controller tests' `authorization` block covers it; a separate policy test earns its place only when controller tests mock the policy or assert just that it is wired.
