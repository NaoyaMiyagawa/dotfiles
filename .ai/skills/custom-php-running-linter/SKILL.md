---
name: custom-php-running-linter
description: Runs PHP linting and formatting using Pint. Use after modifying PHP files, or when the user asks to lint or format specific files or directories.
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
