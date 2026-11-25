# Laravel design rules — by kind of code

Before writing a kind of code listed here (a model, a resource, a migration, a route), read its section: these rules decide signatures, files, queries and outputs, so applying them afterwards means rework. The review gate in `../SKILL.md` reports violations of this list and leaves the fix to the writer. Style rules live in [checklist.md](checklist.md). Cross-references use section and rule names, not numbers, so a reorder doesn't break them.

## PHP — design and structure

- Compare value objects through an `equals(self $other): bool` method, not their unwrapped scalars.
- Initialize derived state in the constructor, not lazily; don't add a named constructor/factory that only wraps `new` plus a config read — reserve static named constructors for real logic. A with-er returns `new self(...)` with every argument, so properties can stay `readonly` — not `clone $this` plus an assignment.
- `new` is for value-ish classes only — DTOs, value objects, validation rules, events, jobs, models. A service or action receives its collaborators through the constructor (`private readonly SlugGenerator $slugGenerator`); `app(X::class)` is for entry points and tests. Never `new` a service or action, and never inject the `Container`. Don't register a binding in a service provider solely to call one method.
- Methods on a service/helper class are instance methods, not `static` — the class is container-resolved (see the `new`-vs-`app()` rule under *PHP — design and structure*), and a static method only blocks injection and test doubles.
- A validation/normalization helper returns the validated value with a declared return type — native, or a PHPDoc array shape where native syntax can't express it — so the caller reassigns to the same variable (`$header = $this->validateHeader($header)`). Don't write it as a `void` guard the caller can't type off or chain from.
- Helper methods are `private` by default; `protected` only for an extension point a subclass actually uses. Drop a public method with no external caller and inline a single-use one-line helper into its one caller (a multi-line step stays its own private method — general rule *Methods Read As Steps*).
- Don't take a parameter whose value is identical at every call site — hardcode the invariant inside the method.
- When the same `assert($x instanceof Y)` narrowing repeats across call sites, put it in a typed accessor that asserts once and returns the narrowed type, and let the call sites read that.

## Exceptions

- Exception classes carry the `Exception` suffix and extend `Exception` directly; a `RuntimeException` parent or `ShouldntReport` only with a stated reason.
- Throw the project's `NotImplementedException` for a branch that is deliberately not built yet — not a generic `RuntimeException`/`LogicException` that reads like a real failure.
- A method that only applies to one variant of a type (one action type, one document type) opens its docblock with that variant (`For SendEmail action.`) and throws when called on any other, instead of returning `null`.
- A `try`/`catch` is only for a traced, reachable failure; when two sites hit the same operation but only one can fail, guard that one and leave the other bare.

## Validation

- Name a `FormRequest` for the action it validates, mirroring the REST verb: `Store{X}Request`, `Update{X}Request`.
- A `FormRequest` validates and hands over the input; fetching the model an ID points to belongs in the controller action or its service, not in a request helper method.
- `prepareForValidation()` only transforms input into the shape `rules()` can validate; don't throw from it — anything still malformed is `rules()`'s job to reject.
- Extract non-trivial or reusable validation into a dedicated `Rule` class named for what it checks (`Base64EncodedImage`); reserve inline rules for simple built-in cases.

## Class organization

- Follow the project's established directory per kind; don't add a parallel variant (a fresh `Dto/` beside `DataTransferObjects/`). Prefer moving a legacy-located class to the canonical spot over adding a new class beside it.
- Controllers, form requests and API resources for one model each sit in a subdirectory named for that model, the same name under all three: `Http/Controllers/Invoice/`, `Http/Requests/Invoice/`, `Http/Resources/Invoice/`. The name is the model's, singular. Create the subdirectory even for one file, so nothing has to move when a second arrives.
- Group a cohesive set of related classes into a dedicated sub-namespace to keep the parent folder slim; but leave a genuinely ambiguous or cross-cutting class at the module root rather than forcing it into a sub-directory. A class several modules use belongs in the root module's directory for its kind, not in whichever feature module happened to need it first.
- Keep response/output shaping out of action/service/domain classes — extract a dedicated response class so each has one responsibility.
- An action class exposes only `__invoke()` publicly. When it needs a helper routine, extract that to a dedicated helper/service class rather than adding a second public method on the action.
- An action class is one use case. A small set of operations on one concept (issue / redeem a code, generate / verify a one-time value) lives together in one service class so the data flow is traceable in a single file — not one action class per operation.
- Don't create an input DTO only to wrap a single caller's handful of scalars — pass the parameters. When a DTO or value object already carries the values a method needs, pass it whole instead of unpacking it into arguments.
- A page or view receives its props as an array literal at the controller, spreading service output into it (`[...$invoicePagePropsService->forShow($invoice), 'can' => $permissions]`), so the reader sees the keys there.
- A service takes the values it needs (an enum, an array) as arguments, not the model that holds them — the caller shouldn't write state onto a model just so the callee can read it back, and the service stays free of the model.
- Route a cross-cutting concern such as flow logging through named methods on a dedicated service (`$this->importFlowLogger->fileAccepted(...)`) with a shared message prefix, not scattered `Log::` calls — call sites are then found by reference.
- When a controller fetches or resolves a collaborator only to pass it into an action, move that call into the action — controllers pass through request-derived input, not pre-resolved dependencies the action can obtain itself.
- Extract shared/cross-cutting logic into the repo's designated helper location; don't duplicate the same snippet per call site. Until a second caller exists, keep the logic in its one caller's class, and when extracting, move only the part the callers share.
- A value object owns its own hydration and behaviour — parse a raw array into it via a `fromArray()` named constructor, and put logic that operates on its data on the VO, not inlined in each action/service that consumes it or wrapped in a single-method action class. Same for a model: logic that reads only the record's own fields is a method on the model (`$field->isSourcedFromIssuedAt()`), even with one caller.
- A value object/DTO enforces its own invariants in the constructor — throw when a required argument is empty or invalid rather than accepting it or giving it a permissive default (e.g. don't default a must-be-non-empty array to `[]`; drop the default and validate). A required argument carrying no default also sorts ahead of the optional ones.
- Match the declared namespace to the file's directory — check every added file, not just the one under discussion.

## Authorization (Policies)

- Map controller actions to standard CRUD abilities: `index`/`show` → `viewAny`/`view`, `create`/`store` → `create`, `edit`/`update` → `update`, `destroy` → `delete`. If `show` needs edit-level access, authorize against `update` — don't invent an `edit` ability.
- A condition that decides whether one record allows an action (downloads disabled on this record, record locked) goes in that model's Policy ability, not in the controller or the page-props builder.

## API Resources

- Shape a nested list with a dedicated `JsonResource` + `::collection()`, not an inline `array_map`/`map` closure — one resource class per distinct shape the frontend consumes, named for the model plus the UI surface it feeds (`InvoiceListItemResource` for the index page, `InvoiceDetailResource` for the show page), not for the controller action. A single-action controller's one-off payload is shaped inline in `response()->json([...])`; a resource class earns its place once the shape is reused or nested.
- Serialize a related model (`published_by`, `created_by`) through a small shared resource (`uuid`, `name`, …) reused by every such field, not a flattened `$this->publishedBy?->name`.
- Send a record's identifier as its UUID under a `uuid` / `*_uuid` key; never expose a sequential integer id. A table with no UUID column yet sends `id` with a comment saying so.
- Wrap every relation in `->whenLoaded()`, even one the controller always eager-loads, so a caller that forgets the load gets a missing key instead of an N+1.
- When a resource field stops being consumed, remove it plus the FE TypeScript types, mocks, and selectors in the same PR — no dead serialized fields "just in case".

## Models

- Dispatch domain events from the calling service/action, not inside a model method — side effects belong at the orchestration layer.
- Expose domain operations as purpose-specific model methods — a single-record updater, or intention-revealing state transitions (`markIssued()`, `markClaimed()`) — rather than making callers reach for a generic or bulk mutator directly. Keep the shared generic/bulk method as an internal helper the named methods delegate to.
- Datetime columns cast `immutable_datetime` by default; reach for the mutable `datetime` cast only when a column genuinely needs in-place mutation.
- A custom cast's `get()` and `set()` return null for a null value before transforming it (`array_map()`, `json_decode()`, a value-object constructor); a nullable column and an explicit null assignment both pass null in.

## Eloquent

- Wrap `where(...)->orWhere(...)` alternatives in a closure group (`->where(function (Builder $query) { ... })`) so every top-level condition sits at the same level; a bare `orWhere()` beside other `where()`s ORs against all of them.
- When a query uses raw SQL (`selectRaw()`, `whereRaw()`), run its tests against every database driver the app supports.
- Reach related rows through the relation on the instance you already hold — `$parent->children()->update([...])`, `$comment->post()->lockForUpdate()->first()` — not a fresh `Child::query()->where('parent_id', ...)`; never re-fetch a model the route already bound.
- Fix N+1 loading with eager loading (`with()` / `loadMissing()`), not a cache layer or `once()` memoization.
- Don't set `updated_at` manually unless the value must intentionally diverge from "now" (backfills, replication).
- Prefer time-ordered UUIDs (`Str::orderedUuid()`) populated by a trait/hook, not assigned by hand per record (the bulk-insert path follows the same strategy — core rule *Bulk insert when creating multiple records*).
- Use `firstOrFail()`/`findOrFail()` when a record's existence is an expected invariant — fail loudly at the fetch, not with `first()` + null-guarding. Never reach for `sole()` for a single expected record; `firstOrFail()` reads clearly, `sole()` obscures intent.
- When removing a redundant cast, replace it with the explicit primitive cast (e.g. `'string'`) rather than silently dropping the line; delete any guard the change makes unreachable, confirming against the column's real DB nullability.
- Return `Illuminate\Database\Eloquent\Collection` when that's what consumers need — push conversion into the producer, don't make every call site re-wrap.
- Don't span module boundaries with relationships or `withCount()` — query each side independently and pass the needed data explicitly.
- Push filters into the query (`whereIn`/`where`) instead of fetching a superset and narrowing in PHP with `filter()`/`each()`.
- Call `pluck()`, `count()`, `exists()` and aggregates on the query, not on a hydrated collection: `$document->histories()->orderBy('id')->pluck('status')`, not `->get()->pluck('status')`.
- A membership predicate on a relation (`belongsToGroup($group)`) reads the collection when `relationLoaded()` is true and otherwise runs `exists()` on the relation query — never load a whole to-many relation to test one member.
- Fold a conditional variant of a query into the same call with `when()` and a nested where group instead of running a second query and merging the results in PHP.
- In a model scope, qualify columns with `$this->qualifyColumn('status')`, never a hand-written `'table.status'`. When the model already declares the relation, reach the related rows through it (`whereRelation()`, `whereHas()`, a constrained `with()`) rather than a hand-written `join()` that repeats table names; keep the manual join only when a measured query plan shows the relation form is too slow.

## Migrations

- Backfills and data manipulation use the `DB` facade, never Eloquent models — migrations are time-frozen; models reflect today's schema and will drift.
- A one-off data or index command that every environment needs (a reindex, a backfill command) runs from a migration's `up()` so deploy applies it everywhere — not as a manual step per environment.
- Several migrations added in one PR share one date prefix with a sequential index (`2026_10_01_000001_…`, `2026_10_01_000002_…`) so they sort next to each other.
- Fix a not-yet-merged migration in place; corrective migrations are only for schema already merged or released.
- Column order: foreign keys right after the `id`/`uuid` key columns; audit-style FKs (`created_by`, `updated_by`) near `timestamps()`. A column added to an existing table goes after the last domain column, before the timestamps (`->after('...')`), not at the end. Mirror that order when populating a new model instance: `->associate()` the owning relations right after `new Xxx()`, audit relations next to the timestamps.
- One migration per schema change and one `Schema::table()` call per table per direction — don't split a change across files or `table()` calls without a stated reason.

## Routing

- Place a single-resource action under that resource's route group: `/documents/{document}/resend-email`, not nested under whatever parent surfaced it in the UI.
- Controller class name matches the route resource, and its directory is the model's subdirectory (`Http/Controllers/Document/ResendDocumentEmailController`; see the subdirectory rule under *Class organization*).
- CRUD lives in the resource's one controller (`InvoiceController`); name a single-action controller for its one non-CRUD operation (`ResendInvoiceEmailController`); keep route, controller, directory, and test file names in sync.
- Give every controller action a `Request $request` (or a dedicated `FormRequest`) as its first parameter, even when the body doesn't read it — don't omit it. Break the parameter list across lines.
- Type a route segment that holds an enum value as that enum in the action signature (implicit enum binding) so the framework 404s an unknown value; don't validate it by hand.
- Resource route paths and their route names are plural — `/tokens`, not `/token`; keep path and name in sync.
- Match a request by route name (`$request->routeIs('organizations.did')`), not by path pattern (`$request->is('organizations/*/did.json')`). `routeIs()` returns false before routing resolves the route, so global middleware still has to use `is()`.
- Register routes in the app's existing route files (`web.php`/`api.php`); don't add a new custom route file for a feature.

## Queue / Job dispatch

- When one job is dispatched per record, resolve configuration that is identical for the whole batch once in the dispatcher and pass it to each job, when that saves each job a query. When it saves nothing, take whichever form is simpler.
- Use `ShouldQueueAfterCommit` for listeners/jobs whose effects depend on a DB write committing first.
- Job-level gating — skip-if, overlap locks, rate limits — goes in queue middleware (`Skip`, `WithoutOverlapping`, `RateLimited`) where the framework's middleware can express it; inline it in `handle()` only when the gate must wrap the work itself (acquire/release around a custom lock).

## Config / env

- Base-URL envs: name the config key with a `_base_url` suffix and strip trailing slashes at read time (`rtrim(env('CDN_BASE_URL', ''), '/')`) so callers never defend against `//path` joins.
- Sync `.env.example` (and mirrored `docker-compose*.yml` / FE `.env.example`) in the same PR as any env var change.
- A value that doesn't vary by environment (a TTL, a limit) is a class constant, not a config key or env var — don't add a config file for one such value.

## Enums

- Put payload, serialization, and display-label logic on the enum itself (`toApiPayload()`, `labelForCli()`), not a `match` at the call site, with a dedicated test guarding an external contract.
- Internal arrays, registries, and DTOs hold enum instances; convert with `->value` only at the serialization boundary (resource, outbound payload, bulk insert). Keeping the enum lets downstream logic call its methods instead of re-hydrating with `::from()`.
