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

## Pest Rules

1. Write tests in Pest style.
2. Import Pest Laravel functions when used:
   - `use function Pest\Laravel\actingAs;`
   - `use function Pest\Laravel\mock;`
3. `describe('<method-name>')` must match the subject public method.

## Command

Run tests using:

```bash
./vendor/bin/sail test [filepath]

# or use parallel for faster test run
./vendor/bin/sail test --parallel [filepath]
```

If sail is not running, sail up only necessary containers for running tests. Most of the time, it's only app and mysql, sometimes minio.

```bash
./vendor/bin/sail up -d app mysql
```

## Coding standard
### beforeEach

1. Create local variables first, then assign to `$this` properties.
2. Exception: static literal values that do not come from factories.
3. Set fakes in `beforeEach` when needed (`Event::fake([...])`, `Storage::fake(...)`).

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

4. Use app(Xxx::class) in each test case for better IDE support when the class is the test target.

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

- Prefer factory state methods when available to reduce hardcoding keys.
  e.g. `withStatus(XxxStatus $status)` when having `status` column.
  If there is no existing state method for a column, you can add it.
  Prefer this order of state methods in factory class.
  e.g.
  - definitions() ... factory's default method
  // relationships
  - forXxx($modelOrFactory) ... only when we need to specify relationship name with ->for().
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

Use `// Act & Assert` for compact tests only.

#### Feature Test Pattern

1. Use `route('...')` to build request URLs.
2. Prefer combining request and assertion fluently when clear.

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

3. Use `describe()` blocks effectively to group same category of test cases
  By default, you can have these ones.
  ```php
  describe('{method name}', function () {
    describe('happy paths', function () {
      // Test successful cases
    });

    describe('unhappy paths', function () {
      // Test error cases
      // e.g.)
        it('returns 404 for workflow from another org', function () {
          // ...
        });
    });

    describe('validations', function () {
      // Test validation error cases
    });

    describe('authorization', function () {
      // Test policy middleware logic
        // e.g.)
        it('returns 403 for workflow from another org group', function () {
          // ...
        });
    });
  });
  ```

#### Action/Service class test
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

- Don't use `->and()`, just use two separate lines for cleanliness.
- Use `foreach` over `assert(x)->each()` for cleanliness.
- For validation failures, always assert with the full expected message map, not the field-only form. Pass the expected message via a dataset column so each case documents its own failure.
  ```php
  // Good
  $response->assertInvalid(['file' => 'The file field is required.']);

  // Bad — field-only or partial match
  $response->assertInvalid(['file']);
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
Test file name must mirror the production class name verbatim, including suffixes like `Job`, `Service`, `Action`, `Controller`.

- `RunManualPostIssuanceActionJob` → `RunManualPostIssuanceActionJobTest.php` (not `RunManualPostIssuanceActionTest.php`)
- `MPIADocumentsController` → `MPIADocumentsControllerTest.php`

### Controller test scope
When a controller delegates to an Action / Service / Job / Executor class that has its own dedicated test, keep controller tests thin. Mock the delegated class and assert on the call boundary; do **not** re-cover its domain logic.

A controller test should cover only:
1. **One success case** — verifies the controller passes the right args to the action class (mock `->shouldReceive(...)` with expected args).
2. **Validation cases** — request validation rules that live in the controller / FormRequest.
3. **One rejection case** — verifies the controller catches the action's exception and returns the expected response. No need to enumerate every exception message; that belongs in the action's test.
4. **Authorization cases** — policy / middleware behavior owned by the controller layer.

Domain branching, error variants, and side-effects belong in the Action / Service / Job test, not duplicated in the controller test.

### Regression tests
When adding a test to guard against a specific 500/error you just fixed, assert only the success contract (e.g. `assertOk()` / page renders) on the route that previously broke. Don't over-specify by enumerating `->missing(...)` checks for fields the PR removes or by asserting the absence of every offending shape — those add maintenance cost without strengthening the regression guarantee.

### Test target exclusion
No need to write tests for the following classes:
- Resource
- DTO
- Event

### Verify tests
Refer [~/dotfiles/.ai/skills/custom-php-running-test]
