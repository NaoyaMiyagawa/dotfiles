---
name: custom-php-running-static-analysis
description: Runs PHP static analysis using PHPStan with project-specific scope rules. Use when PHP code changes need static analysis; run full-application analysis only when the user explicitly requests it.
---

# Custom PHP Running Static Analysis

## Command

### Specific file
Use this after changing any php code.

```bash
./vendor/bin/sail exec app ./vendor/bin/phpstan analyze {filepath}
```

### Run entire app
This is only when user ask you to run for all and fix phpstan errors entirely because it takes long time to complete.

```bash
./vendor/bin/sail exec app ./vendor/bin/phpstan
```
