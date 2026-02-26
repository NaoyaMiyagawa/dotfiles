---
name: custom-php-running-static-analysis
description: Run static analysis rules for php code. Use after changing any php code.
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
