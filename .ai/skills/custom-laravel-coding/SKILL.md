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

### Auth
1. Use `Auth::user()` over `$request->user()` in controller for better IDE support on Cursor.
2. Access `Auth::user()` only on presentation layers such as Controllers.

### Eloquent
1. Always start from `::query()` for better IDE support.
2. Use dedicated `whereXxx` methods (e.g. `whereLink`, `whereBetween`, `whereNot`) when applicable.
3. Use scope defined in model when applicable.
4. Omit `->value` when enum is used in value part (e.g. `->where('status', UserStatus::Active)`, `->update(['status' => UserStatus::Active])`)

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

### Email sending
- Use `ShouldQueueAfterCommit` if sending is done in listener or job.
