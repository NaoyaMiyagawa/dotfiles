---
name: custom-laravel-coding
description: Applies Laravel backend coding conventions for PHP implementation and refactoring. Use when implementing or refactoring Laravel services, controllers, models, actions, or related backend application logic.
---

## Rules

Keep changes consistent with existing project patterns unless asked to refactor.

### PHP
1. Use `use` imports instead of inline FQNs like `\App\Models\User`.
2. Prefer calling `__invoke()` for invokable classes to improve IDE support. e.g. `app(Xxx::class)->__invoke()`
3. Always add line breaks to constructor args
    ```php
    public function __construct(
        public readonly string $xxx,
    ) {}
    ```
4. Use `final` `readonly` for ValueObject, DTO. For a value holder with no transformation logic, expose data as `public readonly` properties instead of `private` fields plus getter methods — a getter that only returns its backing field adds ceremony without encapsulating anything. Reach for a private field + accessor only when the accessor does real work (validation, derivation, formatting).
5. Use string interpolation when possible for better readability. (e.g. `"This is {$user->name}"`) When interpolation isn't feasible (e.g. a reusable format string or positional args), prefer `vsprintf` over `sprintf`.
6. Use named args when method calls goes multiple lines due to line length.
7. Don't wrap with bracket when instantiating a class. Good: `new Xxx()->...`.
8. Prefer `$x === null` over `is_null($x)` for null checks.
9. **Use strict comparison for membership checks.** Pass `true` as the third arg to `in_array()` / `array_search()` when testing identity-style membership — allowlists, id lists, role/status lists. Loose comparison invites type juggling (`0 == 'foo'`, `'1' == 1`), a correctness and security risk in access checks.
10. Prefer guard clauses / early returns over wrapping the main path in a positive `if`. Invert the condition and bail out first.
11. Prefer collection pipelines (`collect($items)->map(...)->filter(...)`) over raw array functions in transformation/serialization code, for readability and chainability.
12. Use one consistent spelling for identifiers across a file — prefer American English (e.g. `organization`, not `organisation`). Don't mix `-ize`/`-ise`. Comments are exempt. Preserve the conventional casing of acronyms and mixed-case terms in identifiers (`OAuth`, `ID`, `URL`, `HTTP` — not `Oauth`/`Id`/`Url`).
13. **Comment workarounds with their removal condition.** When you add a compatibility guard or workaround (e.g. code that only matters outside the standard dev/runtime environment), leave an inline comment stating *why* it exists and *when it can be removed*, so future cleanup is self-evident — don't bury the rationale in the PR description alone.
14. **Treat a nullable return type as a contract to guard at every call site.** When a method is declared `?T`, dereference its result null-safely (`?->`) or with an explicit null check *everywhere* it's used — don't leave some sites guarded and others bare. A mix of guarded and unguarded dereferences of the same nullable accessor is a latent null crash; the already-guarded site tells you the null case is real. Choose a sensible default for the absent case (often: skip or permit when there is nothing to enforce).
15. **Compare value objects through an `equals()` method, not their unwrapped values.** Give a value object an `equals(self $other): bool` and call `$a->equals($b)` rather than reaching into both and comparing raw scalars (`$a->value() === $b->value()`). The intent reads at the call site and the comparison rule lives in one place.
16. **Reach for the framework's first-party helpers over hand-rolled primitives.** For a common operation, prefer a provided helper to a manual loop over language built-ins — e.g. `Illuminate\Filesystem\Filesystem` (`ensureDirectoryExists()`, `deleteDirectory()`) instead of recursive `scandir`/`is_dir`/`unlink`/`rmdir`, and `Str`/`Arr`/collection helpers over ad-hoc string/array fiddling. Less code to get wrong and the intent is explicit. This applies in test setup/teardown too.
17. **Initialize derived state in the constructor, not lazily.** When a property can be computed from the constructor's inputs, set it in the constructor rather than behind a lazy getter or a separate setter. And don't add a named constructor/factory (`fromConfig()`, `make()`) that only wraps `new` with a config read — construct directly at the call site. Reserve a static named constructor for when it encapsulates real logic (see Exceptions).
18. **Resolve from the container with `app()`.** Prefer `app(X::class)` over injecting a `Container` and calling `$this->container->make(X::class)`. Don't register a binding in a service provider solely to call one method — call the method directly.
19. **Build URLs with `route()`, never hardcoded path/URL string literals.** Pass `absolute: true` when an absolute URL is required. Don't concatenate a base/`app_url` with a literal path — a named route survives path changes and keeps the URL in one place.

### Abstraction
- **Prefer a direct `match` (or a small map) over a registry / service-provider registration pattern for dispatch you fully own.** A registry that entries register themselves into earns its complexity only when something *external* (a plugin, a separate package) must extend the set. When you own every case, a `match` that returns the right handler keeps the wiring in one readable place. Don't add indirection (an interface, a registry, a factory) for a single in-house caller until a second caller or a real extensibility need appears.

### Exceptions
- **Encapsulate error keys and status codes in static named constructors on the exception class.** Call sites should `throw DomainException::invalidRequest()` rather than passing a message key and HTTP status at each `throw`. The mapping lives in one place and call sites stay declarative.

### Validation
- **Put request validation in a `FormRequest`, not inline in the controller.** Rules, authorization, and messages belong in the dedicated request class; the controller receives already-validated input.

### Class organization
1. **Put a class in a directory named for its kind, grouped by domain.** Value objects under `ValueObjects/`, DTOs under `DataTransferObjects/`, enums under `Enums/` — each with a domain sub-namespace (`Enums/{Domain}/`) — rather than nesting them inside a service's generic `Data/` (or similar) folder. The kind should be legible from the path, and the domain grouping should reflect where the type is actually used, not where it happened to be written first.
2. **Follow the project's established directory for each kind; don't introduce a parallel variant.** If the codebase is standardising on one location/name for a kind (e.g. `DataTransferObjects/`), don't add a sibling under a competing name (e.g. a fresh `Dto/`). When you find a class under a legacy or ad-hoc location, prefer moving it to the canonical one over adding a new class beside it.

### PHPDoc / typing
1. **Prefer `list<T>` over `array<int, T>`** in PHPDoc for zero-indexed sequential arrays (anything produced by `map`, `values()`, `explode`, etc.). `list<T>` states the "no string or sparse keys" guarantee that `array<int, T>` only implies, and the analyzer enforces it.
2. **Annotate structured associative arrays with array-shape syntax** (`array{id: int, name: string, fields?: list<...>}`) instead of a bare `array` or `array<string, mixed>`. The shape documents the contract at boundaries (DTO/value-object constructors, methods returning decoded API or JSON payloads) and lets static analysis catch missing or misspelled keys. Nest `array{...}` and `list<>` freely.
3. **Re-index before returning a documented `list<T>`.** Operations that look list-producing — `->all()`, `->filter()`, `array_filter()`, unsetting elements — can preserve the original keys, so the result is no longer zero-based. Call `->values()` (or `array_values()`) before returning so the value genuinely satisfies the `list<T>` contract the analyzer enforces; otherwise the annotation and the runtime shape silently diverge.
4. **Add a summary PHPDoc to a method or class whose purpose isn't obvious from its name.** For domain- or protocol-specific logic, an unfamiliar algorithm, or a non-trivial transformation, a one-line docblock stating *what it is / why it exists* orients the next reader who lacks that context. Skip it when the name already says everything — a docblock that only restates the signature is noise.

### Auth
1. Use `Auth::user()` over `$request->user()` in controller for better IDE support on Cursor.
2. Access `Auth::user()` only on presentation layers such as Controllers.
3. **Don't add PHPDoc for `Auth::user()` return type.** IDEs already resolve it via the framework's stubs; the annotation is redundant and rots if the stubs improve.

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

### Models
1. **Cast datetime/timestamp columns with `immutable_datetime` by default.** Reach for the mutable `datetime` cast only when a column genuinely needs in-place mutation.
2. **No `$fillable` / mass assignment.** Set attributes explicitly. When creating a record by copying an existing one, use `->replicate()` rather than re-listing fields.
3. **Define query scopes with the `#[Scope]` attribute, not the legacy `scopeXxx()` method.**

### Eloquent
1. Always start from `::query()` for better IDE support.
2. Use dedicated `whereXxx` methods (e.g. `whereLink`, `whereBetween`, `whereNot`) when applicable.
3. Use scope defined in model when applicable.
4. Omit `->value` when enum is used in value part (e.g. `->where('status', UserStatus::Active)`, `->update(['status' => UserStatus::Active])`). This depends on the column being declared with an enum cast on the model — add the cast first if it's missing.
5. **Update through the relation, not a fresh query.** When you have a parent model and want to update its children, prefer `$parent->children()->update([...])` over `Child::query()->where('parent_id', $parent->id)->update([...])`. The relation already encodes the constraint and reads more clearly.
6. **Don't set `updated_at` manually.** Let the framework manage timestamps. Only touch them explicitly when the value must intentionally diverge from "now" (e.g. backfills, replication).
7. **Prefer `datetime_immutable` cast for new datetime columns.** The codebase is gradually migrating off mutable `datetime` casts toward `CarbonImmutable`. Don't introduce new mutable date columns unless there is a concrete reason.
8. **Single-record updates: assign attributes and `->save()`.** When you already hold the model instance, prefer attribute assignment + `->save()` over `Model::query()->where('id', $id)->update([...])`. The query-builder form reads as a bulk update at a glance and obscures intent.
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
9. **Prefer time-ordered UUIDs for generated identifiers.** When a model uses a UUID key, generate it with the ordered/sequential variant (`Str::orderedUuid()`) rather than a random UUID, for better DB index locality. Keep the model's `creating`/`booting` hook and any bulk-insert path on the same strategy so no two write paths produce different formats.
10. **Removing a redundant cast: make the type explicit, don't silently drop it.** When a cast becomes obsolete, prefer replacing it with the plain primitive cast (e.g. `'string'`) over deleting the line — a missing cast is ambiguous between "deliberately default" and "forgotten", especially for id / primary-key columns. Only drop the line entirely when the default is unmistakable. If removing the cast also makes a conditional unreachable (e.g. a null guard that can no longer be true once the value is always a string), delete that dead branch in the same change, and confirm against the column's real DB nullability rather than assuming.

### Migrations
1. **Use the `DB` facade for backfills and data manipulation in migrations, not Eloquent models.** Migrations are time-frozen and run against the schema at that point in history; Eloquent models reflect today's schema. A model-based backfill will silently break (or behave inconsistently) once the model's columns, casts, or accessors drift away from what the migration expected.
    ```php
    // Good — DB facade, raw column values, independent of any future model changes
    DB::table('{table}}')->insert([
        '{column}' => '...',
    ]);

    // Bad — couples the migration to future model state
    Model::query()->create([...]);
    ```
2. **Fix a not-yet-merged migration in place; don't stack a corrective one.** While a migration is still on an unmerged branch (or a spike), edit the original file to fix a schema/column mistake rather than adding a second "fix" migration on top. Reserve additive corrective migrations for schema that is already merged or released.

### Routing
1. **Place a single-resource action under that resource's route group**, not under whatever parent happened to surface it. A "resend email for this document" action belongs at `/documents/{document}/resend-email`, not `/runs/{run}/documents/{document}/resend-email`, even if the UI entry point is the run page.
2. Controller class name and directory should match the route resource (e.g. `Http/Controllers/Documents/ResendDocumentEmailController`).
3. **Prefer route-model binding + policy for resource auth** over receiving an id in the request body and re-resolving it in the controller. `POST /users/{user}/switch` + `->can('switch', 'user')` beats `POST /admin/organisations/switch` with `organization_id` in `FormRequest::authorize()`. Bonus: denials return `403` / unknown ids `404` instead of a silent validation error.
4. **Use the `->can('ability', 'model')` route helper for model-bound policy enforcement.** Prefer it over `->middleware(['can:ability,model'])` or `Authorize::using(...)` — it reads as a route-level declaration that pairs naturally with model binding.
5. **Name a controller for the specific operation it performs, not a generic resource.** A controller that resends an invoice email is `ResendInvoiceEmailController`, not a catch-all `InvoiceController`; the class name should tell a reader what the endpoint does. Keep the route, controller, and directory names in sync (rule 2).
6. **Match the action method to the endpoint's shape.** When an endpoint maps to a CRUD operation, use the resourceful method name (`index`, `show`, `store`, `update`, `destroy`) on the controller rather than `__invoke`. Reserve a single-action `__invoke` controller for operations that are genuinely not resourceful. Don't default every controller to `__invoke`.

### Bulk insert
When creating more than one record for the same table/model, use bulk `{Model}::insert()` with chunking:
```php
$organization->users()
    ->chunkById(self::INSERT_CHUNK_SIZE, function (Collection $users): void {
        $now = CarbonImmutable::now();

        $notificationsData = $users
            ->map(function (User $user) use ($now) {
                $notification = new UserNotification();
                $notification->user()->associate($user);
                $notification->sent_at = $now;
                $notification->updateTimestamps();

                return $notification->getAttributes();
            });

        UserNotification::insert($notificationsData->toArray());
    });
```

**Bulk `insert()` bypasses model events.** It skips the model's `creating`/`saving` hooks, attribute casts, and automatic timestamp management — so every column those hooks would have populated (UUIDs, timestamps, derived defaults) must be set explicitly in the inserted rows. If you intentionally diverge from a hook's default on this path (e.g. a different UUID strategy for index locality), apply the same change to the model hook too, so no two write paths produce different formats for the same column.

### Queue / Job dispatch
- Prefer the `dispatch(new JobClass(...))` helper over `JobClass::dispatch(...)` for better IDE / phpstan support on constructor args.
- Use `ShouldQueueAfterCommit` for listeners and jobs whose effects depend on a DB write completing first (e.g. emails referencing a freshly-created row).

### Config / env
1. **URL config values**: when an env holds a base URL (e.g. `https://cdn.nexus.accredify.io`), name the config key with a `_base_url` suffix (`cdn_base_url`, not `cdn_bucket`) and strip trailing slashes at read time: `rtrim(env('CDN_BASE_URL', ''), '/')`. Callers should not have to defend against `//path` joins.
2. **Sync `.env.example` when env vars change.** When you remove or rename a `env('FOO')` usage, update `.env.example` (and `docker-compose*.yml` / FE `.env.example` if mirrored) in the same PR. Stale entries in `.env.example` mislead new devs and trip up deploys.

### Translations
- All user-facing strings — including enum labels surfaced in UI, validation messages, and view copy — go through `__()` / translation files. Don't hardcode English literals in enums, resources, or Blade/JSX.
