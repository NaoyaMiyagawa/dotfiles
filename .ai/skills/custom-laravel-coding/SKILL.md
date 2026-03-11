---
name: custom-laravel-coding
description: Applies Laravel backend coding conventions for PHP implementation and refactoring. Use when implementing or refactoring Laravel services, controllers, models, actions, or related backend application logic.
---

# Custom Laravel Coding

## Scope

Apply this skill only for Laravel backend work.

## Execution Notes

- Keep changes minimal and consistent with existing project patterns unless you are asked to refactor existing codebase.
- Do not apply this skill to non-PHP or non-Laravel tasks.

## Rules

### PHP
1. Use `use` imports instead of inline FQNs like `\App\Models\User`.
2. Prefer calling `__invoke()` for invokable classes to improve IDE support. e.g. `app(Xxx::class)->__invoke()`
3. Always add line breaks to constructor args
    ```php
    public function __constructor(
        public readonly string $xxx,
    )
    {}
    ```
4. Use `final` `readonly` for ValueObject, DTO

### Auth
1. Use `Auth::user()` over `$request->user()` in controller for better IDE support on Cursor.
2. Access `Auth::user()` only on presentation layers such as Controllers.
$$
