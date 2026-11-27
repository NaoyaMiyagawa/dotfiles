---
name: custom-php-sail
description: Run PHP/Laravel tooling through Sail (Pint linter, PHPStan static analysis, Pest/PHPUnit tests, and non-interactive Tinker). Use when linting, analyzing, testing, or evaluating PHP snippets in a Laravel project.
---

# PHP / Laravel Sail Commands

## Containers (Sail only)

Tests, PHPStan, and Tinker must run inside Sail so PHP extensions, `.env`, DB, and services match the project. Never substitute host `php`/`pest`/`phpunit`/`composer test` unless the user says the project doesn't use Sail. If `./vendor/bin/sail` is missing or Docker is down, stop and say so.

Confirm Sail is up (`./vendor/bin/sail ps`). If down, start only the services needed (check `docker-compose.yml` / `compose.yaml`, typically `app` + DB):
```bash
./vendor/bin/sail up -d app mysql
```

## Lint / format (Pint)

```bash
vendor/bin/pint -p --dirty              # modified files only
vendor/bin/pint -p {file/directory...}  # specific paths
```

## Static analysis (PHPStan)

```bash
./vendor/bin/sail exec app ./vendor/bin/phpstan analyze {filepath}  # after PHP changes
./vendor/bin/sail exec app ./vendor/bin/phpstan                     # full app (only when explicitly asked — slow)
```

## Tests (Pest / PHPUnit)

```bash
./vendor/bin/sail artisan test {filepath}  # pass changed test paths or --filter=; omit for full suite
```

- Do **not** pass `--parallel` locally (slower than single-process on Sail).
- For module-wide or full-repo runs, prefer committing, pushing, and letting sharded CI run it — only when committing/pushing is already part of the task.

## Tinker (one-off PHP evaluation)

Always pass `--execute` (never open an interactive REPL) and use `dump()` / `dd()` to surface values (bare expressions print nothing). Single-quote multi-line snippets so the shell doesn't expand PHP `$vars`:

```bash
./vendor/bin/sail artisan tinker --execute='dump(User::count());'
./vendor/bin/sail artisan tinker --execute='
$u = User::factory()->make();
dump($u->toArray());
'
```

Never run state-mutating code (writes, deletes, jobs, external calls) unless explicitly asked.
