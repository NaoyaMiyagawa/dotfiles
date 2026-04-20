---
name: custom-php-running-test
description: Runs PHP/Laravel tests (PHPUnit/Pest) only through Laravel Sail. Use when running phpunit, pest, artisan test, or any PHP/Laravel test command.
---

## Required command (Sail only)

Tests must run inside the Sail stack so PHP extensions, `.env`, DB, and services match the project.

```bash
./vendor/bin/sail artisan test {filepath}
```

Omit `{filepath}` to run the full suite, or pass a path, filter, or `--filter=` as needed.

## Containers must be running (minimal stack)

Before running tests, confirm Sail services are up (e.g. `./vendor/bin/sail ps`). If the stack is down, start **only the services the test run needs**—use `docker-compose.yml` / `compose.yaml` in the project for exact service names.

Typical minimum:

- `app` (required so `sail artisan test` runs in the app container)
- Any backing services tests hit (often a DB service such as `mysql`, `mariadb`, or `pgsql`; sometimes `redis` or others)

Example (replace names with this project’s services):

```bash
./vendor/bin/sail up -d app mysql
```

If the minimal set is ambiguous, `./vendor/bin/sail up -d` for the default profile is acceptable; prefer listing only needed services when you want fewer containers.

## Do not use (wrong environment)

Do **not** invoke any of these for this project unless the user explicitly says Sail is not used:

- `pest`, `./vendor/bin/pest`, `php vendor/bin/pest`
- `php artisan test` (without Sail)
- `./vendor/bin/phpunit` on the host
- `composer test` if it maps to raw Pest/PHPUnit on the host

If `./vendor/bin/sail` is missing or Docker is down, stop and say so—do not substitute a host-side test runner.

## Scoped runs (optional)

When the user only changed specific files, prefer passing those test paths to `sail artisan test` as above.
