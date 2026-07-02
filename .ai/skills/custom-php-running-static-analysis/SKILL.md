---
name: custom-php-running-static-analysis
description: Runs PHP static analysis using PHPStan with project-specific scope rules. Use when PHP code changes need static analysis; run full-application analysis only when the user explicitly requests it.
---

# Custom PHP Running Static Analysis

## Command

### Specific file
Use this after changing any PHP code.

```bash
./vendor/bin/sail exec app ./vendor/bin/phpstan analyze {filepath}
```

### Run entire app
Only when the user explicitly asks to analyze and fix PHPStan errors app-wide — it takes a long time to complete.

```bash
./vendor/bin/sail exec app ./vendor/bin/phpstan
```
