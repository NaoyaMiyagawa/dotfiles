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

### Test target exclusion
No need to write tests for the following classes:
- Resource
- DTO
- Event

### Verify tests
Refer [~/dotfiles/.ai/skills/custom-php-running-test]
