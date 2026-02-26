---
name: custom-php-running-linter
description: Run linting/formatting rules for php code. Use after changing any php code.
---

# Custom PHP Running Linter

## Command
### Only for modified files

```bash
vendor/bin/pint --parallel --dirty
```

### Specific files or directories

```bash
vendor/bin/pint --parallel {file/directory paths}
```
