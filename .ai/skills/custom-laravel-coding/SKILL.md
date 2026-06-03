---
name: custom-laravel-coding
description: Applies Laravel backend coding conventions for PHP implementation and refactoring. Use when implementing or refactoring Laravel services, controllers, models, actions, or related backend application logic.
---

## Scope

Apply this skill only for Laravel backend work.

## Execution Notes

- Keep changes minimal and consistent with existing project patterns unless you are asked to refactor existing codebase.
- Do not apply this skill to non-PHP or non-Laravel tasks.

## Rules

### PHP
1. Use `use` imports instead of inline FQNs like `\App\Models\User`.
2. Prefer calling `__invoke()` for invokable classes to improve IDE support. e.g. `app(Xxx::class)->__invoke()`
3. Always add line breaks to constructor args
    ```php
    public function __constructor(
        public readonly string $xxx,
    )
    {}
    ```
4. Use `final` `readonly` for ValueObject, DTO
5. Use string interpolation when possible for better readability. (e.g. `"This is {$user->name}"`)
6. Use named args when method calls goes multiple lines due to line length.
7. Don't wrap with bracket when instanciating a class. Good: `new Xxx()->...`.
8. Prefer `$x === null` over `is_null($x)` for null checks.

### Auth
1. Use `Auth::user()` over `$request->user()` in controller for better IDE support on Cursor.
2. Access `Auth::user()` only on presentation layers such as Controllers.

### Authorization (Policies)
- Map controller actions to standard CRUD policy abilities: `index`/`show` → `viewAny`/`view`, `create`/`store` → `create`, `edit`/`update` → `update`, `destroy` → `delete`. Don't invent abilities like `edit` on the policy — if `show` requires edit-level access for an editable resource, authorize against `update`, not a non-existent `edit` method.

### API Resources
- When a `JsonResource` field stops being consumed by the frontend, remove it from the resource, the FE TypeScript types, mocks, and any selectors in the same PR. Don't leave dead serialized fields behind "just in case" — they mislead future readers about the contract.

### Domain language
Before writing a raw conditional involving a domain concept (user role, org membership, status, capability), grep the relevant model (`User`, `Organization`, etc.) for an existing predicate or accessor — `isXxx()`, `hasXxx()`, `getXxx()` — and reuse it instead of duplicating the check inline.

```php
// Bad — inline re-derivation
if ($user?->organization_id === Organization::INTERNAL_ID && $user->organization->sso_enabled) { ... }

// Good — reuse domain helpers
if ($user?->isInternalUser() && Organization::getInternalOrganization()?->hasEnableSsoLogin()) { ... }
```

### Eloquent
1. Always start from `::query()` for better IDE support.
2. Use dedicated `whereXxx` methods (e.g. `whereLink`, `whereBetween`, `whereNot`) when applicable.
3. Use scope defined in model when applicable.
4. Omit `->value` when enum is used in value part (e.g. `->where('status', UserStatus::Active)`, `->update(['status' => UserStatus::Active])`)
5. **Update through the relation, not a fresh query.** When you have a parent model and want to update its children, prefer `$parent->children()->update([...])` over `Child::query()->where('parent_id', $parent->id)->update([...])`. The relation already encodes the constraint and reads more clearly.
6. **Don't set `updated_at` manually.** Let the framework manage timestamps. Only touch them explicitly when the value must intentionally diverge from "now" (e.g. backfills, replication).
7. **Single-record updates: assign attributes and `->save()`.** When you already hold the model instance, prefer attribute assignment + `->save()` over `Model::query()->where('id', $id)->update([...])`. The query-builder form reads as a bulk update at a glance and obscures intent.
    ```php
    // Bad — looks like bulk update at first glance
    ActionRun::query()
        ->where('id', $actionRun->id)
        ->update([
            'status' => ActionRunStatus::Running,
            'started_at' => now(),
        ]);

    // Good
    $actionRun->status = ActionRunStatus::Running;
    $actionRun->started_at = now();
    $actionRun->save();
    ```

### Routing
1. **Place a single-resource action under that resource's route group**, not under whatever parent happened to surface it. A "resend email for this document" action belongs at `/documents/{document}/resend-email`, not `/runs/{run}/documents/{document}/resend-email`, even if the UI entry point is the run page.
2. Controller class name and directory should match the route resource (e.g. `Http/Controllers/Documents/ResendDocumentEmailController`).

#### Bulk insert
When it is expected to create more than 1 record for a same table/model, use bulk insert using `{Model}::query()->insert();` with chunk.
e.g.
```php
      $organization->users()
            ->chunkById(self::INSERT_CHUNK_SIZE, function (Collection $submissions) use ($user): void {
                $now = CarbonImmutable::now();

                $notificationsData = $submissions
                    ->map(function () {
                        $notification = new UserNotification();
                        $notification->user()->associate($user);
                        $notification->sent_at = $now;
                        $notification->updateTimestamps()

                        return $notificationData->getAttributes();
                    });
                Notification::insert($notificationsData->toArray());
            });
```

### Queue / Job dispatch
- Prefer the `dispatch(new JobClass(...))` helper over `JobClass::dispatch(...)` for better IDE / phpstan support on constructor args.
- Use `ShouldQueueAfterCommit` for listeners and jobs whose effects depend on a DB write completing first (e.g. emails referencing a freshly-created row).

### Config / env
1. **URL config values**: when an env holds a base URL (e.g. `https://cdn.nexus.accredify.io`), name the config key with a `_base_url` suffix (`cdn_base_url`, not `cdn_bucket`) and strip trailing slashes at read time: `rtrim(env('CDN_BASE_URL', ''), '/')`. Callers should not have to defend against `//path` joins.
2. **Sync `.env.example` when env vars change.** When you remove or rename a `env('FOO')` usage, update `.env.example` (and `docker-compose*.yml` / FE `.env.example` if mirrored) in the same PR. Stale entries in `.env.example` mislead new devs and trip up deploys.

### Translations
- All user-facing strings — including enum labels surfaced in UI, validation messages, and view copy — go through `__()` / translation files. Don't hardcode English literals in enums, resources, or Blade/JSX.
