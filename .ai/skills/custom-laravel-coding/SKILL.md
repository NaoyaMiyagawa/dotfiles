---
name: custom-laravel-coding
description: Applies Laravel backend coding conventions for PHP implementation and refactoring. Use when implementing or refactoring Laravel services, controllers, models, actions, or related backend application logic.
---

# Custom Laravel Coding

## Scope

Apply this skill only for Laravel backend work.

## Rules

1. Use `use` imports instead of inline FQNs like `\App\Models\User`.
2. Prefer `__invoke()` for invokable classes to improve IDE support.

## Execution Notes

- Keep changes minimal and consistent with existing project patterns.
- Do not apply this skill to non-PHP or non-Laravel tasks.
