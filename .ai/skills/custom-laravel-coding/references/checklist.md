# Laravel coding checklist — long tail

The review gate in `../SKILL.md` enforces this list; the core rules live there. When a rule here keeps being violated in practice, promote it into the core (move, don't copy). Mechanical rules destined for lint tooling are mapped in [tooling-candidates.md](tooling-candidates.md).

## PHP

1. Use `use` imports instead of inline FQNs like `\App\Models\User`; no `as` aliases unless a name collision forces one.
2. Prefer calling a magic method by name for IDE support: `app(Xxx::class)->__invoke()` for invokable classes, `$uri->__toString()` rather than a `(string)` cast.
3. Always break constructor args across lines:
    ```php
    public function __construct(
        public readonly string $xxx,
    ) {}
    ```
4. Use string interpolation when possible (`"This is {$user->name}"`). When interpolation isn't feasible (a reusable format string, positional args), prefer `vsprintf` over `sprintf`.
5. Always use named args when an argument list is broken across lines — positional args are only for a call that fits on one line:
    ```php
    // Bad
    $this->sender->send(
        $user,
        $template,
        true,
    );

    // Good
    $this->sender->send(
        recipient: $user,
        template: $template,
        queue: true,
    );
    ```
    Also use named args when calling into a package or other external API, even on one line — the parameter order there can be re-ordered out from under you, and named args turn that into a compile-time break.
6. Don't wrap instantiation in brackets: `new Xxx()->...`.
7. Prefer `$x === null` over `is_null($x)`.
8. Strict membership checks: pass `true` as the third arg to `in_array()`/`array_search()` for allowlists, id lists, role/status lists — loose comparison invites type juggling (`0 == 'foo'`), a correctness and security risk in access checks.
9. Use `empty()` for a truthy check on a nullable array or string, not `=== null`.
10. Treat a nullable return type as a contract to guard at every call site: `?->` or an explicit null check everywhere, with a sensible default for the absent case. A mix of guarded and bare dereferences of the same nullable accessor is a latent null crash.
11. Compare value objects through an `equals(self $other): bool` method, not their unwrapped scalars.
12. Initialize derived state in the constructor, not lazily; don't add a named constructor/factory that only wraps `new` plus a config read — reserve static named constructors for real logic.
13. `new` is for value-ish classes only — DTOs, value objects, validation rules, events, models. Resolve actions and services with `app(X::class)`, in tests too; not `new`, not an injected `Container`. Don't register a binding in a service provider solely to call one method.
14. Break a long union/intersection type or generic across multiple lines when it's hard to scan.
15. Order fields/array keys to mirror their source of truth (spec, API contract, referenced document); order constants and methods by lifecycle — success before failure, `markPublished()` before `markArchived()` — and mirror that order in the test file; separate inline-commented groups with blank lines so each comment's scope is unambiguous. When adding a case to a set that already exists in several files — enum, `match` arms, factory states, lang keys, tests — put it beside its closest sibling in every one of them, so the parallel files stay in the same order.
16. Add `#[\Override]` to a method that overrides a parent's.
17. Switch a long arrow function to a classic closure once the expression no longer fits on one line.
18. Assign a non-trivial expression to a named variable before passing it as an argument or chaining off it; don't chain off a custom method's return unless it's designed for chaining (returns `$this`).
19. Don't open two brackets before a line break (`[[`) — give the inner array's opening bracket its own line.
20. Let a comment line run to ~120–130 chars before wrapping; don't hard-wrap it earlier at 80.
21. When a method, property, or class needs a comment, write a `/** */` docblock — reserve single-line `//` comments for inline notes on statements/variables. Prefix a contextual aside (a temporary limitation, a scope note) with `NOTE:`; a why-comment stays bare.
22. Construct immutable datetimes directly (`CarbonImmutable::now()`), not by converting a mutable one (`Carbon::now()->toImmutable()`).
23. A validation/normalization helper returns the validated value with a declared return type — native, or a PHPDoc array shape where native syntax can't express it — so the caller reassigns to the same variable (`$header = $this->validateHeader($header)`). Don't write it as a `void` guard the caller can't type off or chain from.
24. Name a variable that holds a map keyed by a field after that key (`xxxById`, `xxxByKey`) — the name tells the reader the structure at every later use. Applies to plain arrays and `keyBy(...)` results alike.
25. Give each case in a multi-case `match` arm its own line rather than extending the existing one.
26. Gate a minority case behind the domain predicate that names it (`if ($order->hasSubscription()) { ... }`). Don't run its helper on the main path and assign the return value unconditionally: the common path should read as the common path.
27. Helper methods are `private` by default; `protected` only for an extension point a subclass actually uses. Drop a public method with no external caller and inline single-use logic into its one caller.
28. Don't take a parameter whose value is identical at every call site — hardcode the invariant inside the method.
29. Don't annotate a return type the reader can see at a glance — a factory state closure, a one-line `fn () => [...]`.

## Exceptions

- Extract a magic literal — an error code, a limit, a page size — into a named constant on the class that owns it (`public const ERROR_CODE = '...'`, `private const HISTORY_ITEM_COUNT = 5`), not repeated literals at each use site.
- Exception classes carry the `Exception` suffix and extend `Exception` directly; a `RuntimeException` parent or `ShouldntReport` only with a stated reason. Status codes are `Response::HTTP_*` constants, never integer literals — in exceptions, responses, and `abort()` alike.
- Throw the project's `NotImplementedException` for a branch that is deliberately not built yet — not a generic `RuntimeException`/`LogicException` that reads like a real failure.
- Scope a `try`/`catch` to the call that can actually throw, and only for a traced, reachable failure; when two sites hit the same operation but only one can fail, guard that one and leave the other bare.

## Validation

- Name a `FormRequest` for the action it validates, mirroring the REST verb: `Store{X}Request`, `Update{X}Request`.
- Order `FormRequest` methods by processing phase: `prepareForValidation()` → `rules()` → `failedValidation()` → accessor helpers.
- `prepareForValidation()` only transforms input into the shape `rules()` can validate; don't throw from it — anything still malformed is `rules()`'s job to reject.
- Don't scaffold optional hooks you won't use — no empty `authorize()` returning `true`.
- Extract non-trivial or reusable validation into a dedicated `Rule` class named for what it checks (`Base64EncodedImage`); reserve inline rules for simple built-in cases.
- Express a conditional rule inline in the rules array (`Rule::prohibitedIf(...)`, `Rule::requiredIf(...)`, `bail`), not by wrapping the field's rules in `Rule::when()`.

## Class organization

- Follow the project's established directory per kind; don't add a parallel variant (a fresh `Dto/` beside `DataTransferObjects/`). Prefer moving a legacy-located class to the canonical spot over adding a new class beside it.
- Group a cohesive set of related classes into a dedicated sub-namespace to keep the parent folder slim; but leave a genuinely ambiguous or cross-cutting class at the module root rather than forcing it into a sub-directory. A class several modules use belongs in the root module's directory for its kind, not in whichever feature module happened to need it first.
- Keep response/output shaping out of action/service/domain classes — extract a dedicated response class so each has one responsibility.
- An action class exposes only `__invoke()` publicly. When it needs a helper routine, extract that to a dedicated helper/service class rather than adding a second public method on the action.
- An action class is one use case. A small set of operations on one concept (issue / redeem a code, generate / verify a one-time value) lives together in one service class so the data flow is traceable in a single file — not one action class per operation.
- Don't wrap a single caller's handful of scalars in an input DTO — pass the parameters.
- Route a cross-cutting concern such as flow logging through named methods on a dedicated service (`app(ImportFlowLogger::class)->fileAccepted(...)`) with a shared message prefix, not scattered `Log::` calls — call sites are then found by reference.
- When a controller fetches or resolves a collaborator only to pass it into an action, move that call into the action — controllers pass through request-derived input, not pre-resolved dependencies the action can obtain itself.
- Extract shared/cross-cutting logic into the repo's designated helper location; don't duplicate the same snippet per call site.
- A value object owns its own hydration and behaviour — parse a raw array into it via a `fromArray()` named constructor, and put logic that operates on its data on the VO, not inlined in each action/service that consumes it. A second consumer needing the same VO logic is the signal to move it onto the VO.
- A value object/DTO enforces its own invariants in the constructor — throw when a required argument is empty or invalid rather than accepting it or giving it a permissive default (e.g. don't default a must-be-non-empty array to `[]`; drop the default and validate). A required argument carrying no default also sorts ahead of the optional ones.
- Match the declared namespace to the file's directory — check every added file, not just the one under discussion.

## PHPDoc / typing

- Re-index before returning a documented `list<T>` — `->all()`, `->filter()`, `array_filter()`, unsetting elements can preserve keys; call `->values()`/`array_values()` first so the annotation and runtime shape don't diverge.
- When the same `assert($x instanceof Y)` narrowing repeats across call sites, put it in a typed accessor that asserts once and returns the narrowed type, and let the call sites read that.
- Add a one-line summary docblock to a method/class whose purpose isn't obvious from its name (domain/protocol logic, unfamiliar algorithms); skip it when the name says everything. A class docblock describes the class, never its callers — dependencies point inward.
- Type a factory parameter with the concrete factory class (`Model|ModelFactory`), not the generic `Factory<Model>`.
- Link the exact spec/RFC section when implementing a standard — on every related endpoint/class, not just the first. Keep references to internal PRs, spikes, and tickets out of code, though; those belong in the PR description, not a code comment.

## Auth

- `Auth::user()` over `$request->user()` in controllers (IDE support), and only in presentation layers.
- No PHPDoc for `Auth::user()`'s return type — the framework stubs already resolve it.

## Authorization (Policies)

- Map controller actions to standard CRUD abilities: `index`/`show` → `viewAny`/`view`, `create`/`store` → `create`, `edit`/`update` → `update`, `destroy` → `delete`. If `show` needs edit-level access, authorize against `update` — don't invent an `edit` ability.

## API Resources

- Shape a nested list with a dedicated `JsonResource` + `::collection()`, not an inline `array_map`/`map` closure — one resource class per distinct shape the frontend consumes. A single-action controller's one-off payload is shaped inline in `response()->json([...])`; a resource class earns its place once the shape is reused or nested.
- When a resource field stops being consumed, remove it plus the FE TypeScript types, mocks, and selectors in the same PR — no dead serialized fields "just in case".

## Models

- Define query scopes with the `#[Scope]` attribute, not the legacy `scopeXxx()` method.
- Dispatch domain events from the calling service/action, not inside a model method — side effects belong at the orchestration layer.
- No `@property`/`@property-read` PHPDoc block on a model — the IDE-helper stubs and casts already supply the types, so a hand-written block only drifts from the schema.
- Expose domain operations as purpose-specific model methods — a single-record updater, or intention-revealing state transitions (`markIssued()`, `markClaimed()`) — rather than making callers reach for a generic or bulk mutator directly. Keep the shared generic/bulk method as an internal helper the named methods delegate to.

## Eloquent

- Reach related rows through the relation on the instance you already hold — `$parent->children()->update([...])`, `$comment->post()->lockForUpdate()->first()` — not a fresh `Child::query()->where('parent_id', ...)`; never re-fetch a model the route already bound.
- Fix N+1 loading with eager loading (`with()` / `loadMissing()`), not a cache layer.
- Don't set `updated_at` manually unless the value must intentionally diverge from "now" (backfills, replication).
- Prefer time-ordered UUIDs (`Str::orderedUuid()`) populated by a trait/hook, not assigned by hand per record; keep the model hook and any bulk-insert path on the same strategy.
- Use `firstOrFail()`/`findOrFail()` when a record's existence is an expected invariant — fail loudly at the fetch, not with `first()` + null-guarding. Never reach for `sole()` for a single expected record; `firstOrFail()` reads clearly, `sole()` obscures intent.
- When removing a redundant cast, replace it with the explicit primitive cast (e.g. `'string'`) rather than silently dropping the line; delete any guard the change makes unreachable, confirming against the column's real DB nullability.
- Return `Illuminate\Database\Eloquent\Collection` when that's what consumers need — push conversion into the producer, don't make every call site re-wrap.
- Don't span module boundaries with relationships or `withCount()` — query each side independently and pass the needed data explicitly.
- Push filters into the query (`whereIn`/`where`) instead of fetching a superset and narrowing in PHP with `filter()`/`each()`.
- Call `pluck()`, `count()`, `exists()` and aggregates on the query, not on a hydrated collection: `$document->histories()->orderBy('id')->pluck('status')`, not `->get()->pluck('status')`.
- Fold a conditional variant of a query into the same call with `when()` and a nested where group instead of running a second query and merging the results in PHP.

## Migrations

- Backfills and data manipulation use the `DB` facade, never Eloquent models — migrations are time-frozen; models reflect today's schema and will drift.
- Fix a not-yet-merged migration in place; corrective migrations are only for schema already merged or released.
- Head a data/backfill migration with a comment stating why it's needed and what it does — the schema diff shows the columns, not the reason a one-off backfill exists. When it reshapes or canonicalizes an existing stored structure, show the before→after shape concretely in that comment (or the PR body), not just prose — a reviewer without context can't infer the transformation from words alone.
- Column order: foreign keys right after the `id`/`uuid` key columns; audit-style FKs (`created_by`, `updated_by`) near `timestamps()`.

## Routing

- Place a single-resource action under that resource's route group: `/documents/{document}/resend-email`, not nested under whatever parent surfaced it in the UI.
- Controller class name and directory match the route resource (`Http/Controllers/Documents/ResendDocumentEmailController`).
- Name a controller for the specific operation it performs, not a generic catch-all (`ResendInvoiceEmailController`, not `InvoiceController`); keep route, controller, directory, and test file names in sync.
- Register a single-action controller with the array callable `[Controller::class, '__invoke']`, not the bare class string.
- Give every controller action a `Request $request` (or a dedicated `FormRequest`) as its first parameter, even when the body doesn't read it — don't omit it. Break the parameter list across lines.
- Resource route paths and their route names are plural — `/tokens`, not `/token`; keep path and name in sync.
- Register routes in the app's existing route files (`web.php`/`api.php`); don't add a new custom route file for a feature.
- Build JSON responses with the `response()->json(...)` helper rather than instantiating `JsonResponse` by hand — applies in controllers and in response/exception classes that emit JSON.

## Queue / Job dispatch

- Prefer helper functions — `dispatch(new JobClass(...))`, `event(new EventClass(...))` — over the static `::dispatch()` form, for IDE/phpstan completion on constructor args.
- Use `ShouldQueueAfterCommit` for listeners/jobs whose effects depend on a DB write committing first.
- Job-level gating — skip-if, overlap locks, rate limits — goes in queue middleware (`Skip`, `WithoutOverlapping`, `RateLimited`) where the framework's middleware can express it; inline it in `handle()` only when the gate must wrap the work itself (acquire/release around a custom lock).

## Config / env

- Base-URL envs: name the config key with a `_base_url` suffix and strip trailing slashes at read time (`rtrim(env('CDN_BASE_URL', ''), '/')`) so callers never defend against `//path` joins.
- Sync `.env.example` (and mirrored `docker-compose*.yml` / FE `.env.example`) in the same PR as any env var change.
- A value that doesn't vary by environment (a TTL, a limit) is a class constant, not a config key or env var — don't add a config file for one such value.

## Enums

- Put payload/serialization logic on the enum itself (`toApiPayload()`), not a `match` at the call site, with a dedicated test guarding the contract.
- Internal arrays, registries, and DTOs hold enum instances; convert with `->value` only at the serialization boundary (resource, outbound payload, bulk insert). Keeping the enum lets downstream logic call its methods instead of re-hydrating with `::from()`.
