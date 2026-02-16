---
name: custom-laravel-static-analysis
description: Apply project formatting and static analysis rules for Laravel code. Use when preparing code for commit, running Pint, or running PHPStan only on explicit request.
---

# Custom Laravel Static Analysis Conventions

## Scope

Apply this skill when formatting or static analysis is relevant.

## Pint

Always run Pint before finishing implementation:

```bash
vendor/bin/pint --dirty --parallel
```

## PHPStan

Do not run PHPStan unless explicitly requested by the user.

Use:

```bash
# Entire app
./vendor/bin/sail exec app ./vendor/bin/phpstan

# Specific file
./vendor/bin/sail exec app ./vendor/bin/phpstan analyze {filepath}
```
