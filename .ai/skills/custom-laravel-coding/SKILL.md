---
name: custom-laravel-coding
description: Apply Laravel backend modern conventions following used versions in the repository. Use when implementing or refactoring Laravel backend code, service classes, controllers, models, or general PHP application logic.
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
