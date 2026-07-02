---
name: custom-php-running-tinker
description: Runs throwaway PHP/Laravel code through `sail artisan tinker` to test snippets, inspect models, or check framework behavior. Use whenever you need to evaluate PHP against the booted app instead of writing a one-off script.
---

## Required command (Sail only)

Run snippets inside the Sail stack so PHP extensions, `.env`, DB, and services match the project.

```bash
./vendor/bin/sail artisan tinker --execute="{php code}"
```

`--execute` runs the code non-interactively and exits—use it for everything. Do **not** open an interactive REPL (it will hang waiting for input).

Examples:

```bash
# Inspect a model
./vendor/bin/sail artisan tinker --execute="User::count();"

# Check a value / call a service
./vendor/bin/sail artisan tinker --execute="dump(config('app.timezone')); dump(app(SomeService::class)->compute());"
```

For multi-line snippets, pass them with newlines inside the quotes, or pipe via stdin:

```bash
echo '$u = User::factory()->make(); dump($u->toArray());' | ./vendor/bin/sail artisan tinker
```

Use `dump()` / `dd()` to surface values—a bare expression is not echoed in non-interactive mode.

## Containers must be running

Confirm Sail is up first (`./vendor/bin/sail ps`). Start only what the snippet needs—at minimum `app`, plus any DB/service it touches. See `docker-compose.yml` / `compose.yaml` for service names.

```bash
./vendor/bin/sail up -d app mysql
```

## Do not

- Do **not** run `php artisan tinker` on the host (wrong environment)—always go through `./vendor/bin/sail`. If `./vendor/bin/sail` is missing or Docker is down, stop and say so—do not fall back to host PHP.
- Do **not** write a throwaway `.php` script or a temporary route/command—prefer tinker.
- Do **not** use tinker for assertions that belong in a test—write a Pest test instead (see custom-php-running-test).
- Do **not** run state-mutating code (writes, deletes, jobs, external calls) unless the user asked for it.
