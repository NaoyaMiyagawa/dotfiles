---
name: custom-laravel-writing-tests
description: Applies Laravel and Pest testing conventions, including TDD workflow and test structure rules. Use when writing or updating Pest tests, feature tests, factories, datasets, beforeEach setup, or assertion patterns.
---

# Custom Laravel Testing Conventions

## Scope

Apply this skill for test-related tasks in Laravel projects.

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
```

## beforeEach Pattern

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

describe('{class method name}', function () {
  beforeEach(function () {
    // Set fakes e.g. Queue::f
  });

  it('...', function () {

  });
});
```

## Dataset Pattern

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

## Factory Pattern

1. Prefer factory state methods when available to reduce hardcoding keys.
   e.g. `withStatus(XxxStatus $status)` when having `status` column.
   If there is no existing state method for a column, you can add it.
2. Use `->forEachSequence()` when all patterns must be covered.
3. Use `->createOne()` / `->createMany()` for better return types.
4. Prefer `::factory(x)` over `->count(x)` when creating more than one record.

## AAA Comments

Use AAA comments:

```php
// Arrange
// Act
// Assert
```

Use `// Act & Assert` for compact tests only.

## Feature Test Pattern

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
```

## Assertions

- Don't use `->and()`, just use two separate lines since it looks clean.
