---
name: custom-laravel-testing
description: Enforce project testing conventions for Laravel/Pest tests. Use when writing or updating Pest tests, feature tests, factories, datasets, beforeEach setup, and test structure.
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
```

## Dataset Pattern

1. Use `->with()` when cases can be combined.
2. Keep multiline function arguments for dataset-driven tests.
3. For multiple parameters in dataset rows, use named variables in values for readability.

## Factory Pattern

1. Prefer factory state methods when available.
2. Use `->forEachSequence()` when all patterns must be covered.
3. Use `->createOne()` / `->createMany()` for better return types.
4. Prefer `::factory(x)` over `->count(x)`.

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
$response = post(route(...))
  ->assertValid()
  ->assertRedirect();
```
