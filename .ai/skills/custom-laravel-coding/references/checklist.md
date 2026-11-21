# Laravel coding checklist — style rules

The review gate in `../SKILL.md` enforces this list; the core rules live there. Every rule here is style: its fix leaves signatures, files, queries and outputs as they were. A rule whose fix doesn't belongs in [design.md](design.md). When a rule here keeps being violated in practice, promote it into the core (move, don't copy). Mechanical rules destined for lint tooling are mapped in [tooling-candidates.md](tooling-candidates.md). Cross-references use section and rule names, not numbers, so a reorder doesn't break them.

## PHP — formatting and syntax

1. Use `use` imports instead of inline FQNs like `\App\Models\User`; no `as` aliases unless a name collision forces one.
2. Always break constructor args across lines, and the parameters of any method that takes two or more:
    ```php
    public function __construct(
        public readonly string $xxx,
    ) {}
    ```
3. Use string interpolation when possible (`"This is {$user->name}"`). When interpolation isn't feasible (a reusable format string, positional args), prefer `vsprintf` over `sprintf`. A string that is itself multi-line text (CSS, HTML, SQL) is concatenated one logical line per source line, indented as the text would be — not packed two declarations to a line.
4. Always use named args when an argument list is broken across lines — positional args are only for a call that fits on one line:
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
    A call with named args puts one arg per line, even when it would fit on one line (never `new Foo(id: 1, name: 'a')`). The exceptions are a call with a single short named arg (`$session->regenerate(destroy: true)`) and a PHP built-in function, which keeps a named flag inline (`json_decode($json, flags: JSON_THROW_ON_ERROR)`). Keep a positional call that fits on one line on one line (`Artisan::call('scout:import', ['model' => Post::class])`). A trailing array or closure argument may open on the call line and span the lines below (`addField($name, [`). Named args are all or nothing: once a call names one argument, it names every argument (the PHP built-in exception above aside). A one-line call whose values read as themselves stays fully positional (`setPaper('A4', 'landscape')`, `setOrder(1)`), even when calling into a package.
5. Don't wrap instantiation in brackets: `new Xxx()->...`.
6. Break a long union/intersection type or generic across multiple lines when it's hard to scan. When a boolean expression breaks across lines, start each continuation line with its `&&`/`||`, not end the previous line with it.
7. A closure that only returns one expression that fits on one line is an arrow function (`fn (User $user) => $user->name`), not a classic closure. Switch to a classic closure once the expression no longer fits on one line. The exception is an arrow function that returns an array literal (a `map()`/`mapWithKeys()` row): it stays an arrow function, with `=> [` on the arrow line and one entry per line below.
8. Don't open two brackets before a line break (`[[`) — give the inner array's opening bracket its own line. An associative array with two or more keys puts one key per line; the exception is a method with several early `return`s of short arrays, where each stays on one line.
9. Give each case in a multi-case `match` arm its own line rather than extending the existing one.
10. Don't annotate a return type the reader can see at a glance — a factory state closure, a one-line `fn () => [...]`.

## PHP — comments

11. A comment about one short statement, one step of a fluent chain, or one entry of an array literal trails that line when the line stays under the ceiling (`'invoices', // for the billing summary`). Never trail a comment on an `if`/`foreach`/`match` line; put it on its own line above. A comment on its own line above one entry reads as covering the entries below it too. Move it above only when trailing would push the line past the ceiling.
12. Wrap any line, code or comment, past ~120–130 chars; don't hard-wrap a comment earlier at 80.
13. When a method, property, or class needs a comment, write a `/** */` docblock in the multi-line form, even for one sentence — reserve single-line `//` comments for inline notes on statements/variables. Prefix a contextual aside (a scope note, a limitation with no follow-up work) with `NOTE:`; a why-comment stays bare.

## PHP — expressions and null handling

14. Prefer calling a magic method by name for IDE support: `app(Xxx::class)->__invoke()` for invokable classes, `$uri->__toString()` rather than a `(string)` cast.
15. Prefer `$x === null` over `is_null($x)`.
16. Strict membership checks: pass `true` as the third arg to `in_array()`/`array_search()` for allowlists, id lists, role/status lists — loose comparison invites type juggling (`0 == 'foo'`), a correctness and security risk in access checks.
17. Use `empty()` to check a nullable array or string for emptiness, not `=== null`.
18. Treat a nullable return type as a contract to guard at every call site: `?->` or an explicit null check everywhere, with a sensible default for the absent case. A mix of guarded and bare dereferences of the same nullable accessor is a latent null crash.
19. Construct immutable datetimes directly (`CarbonImmutable::now()`), not by converting a mutable one (`Carbon::now()->toImmutable()`).
20. `->reject(fn (?User $user) => $user === null)` over `->filter(fn (?User $user) => $user !== null)` — don't negate a predicate inside `filter()`. Run a side effect per item (printing a line, saving, dispatching) in a `foreach`, not `->each()`; collection methods are for transforms that return a value.
21. Choose a value by case with `match(true)` whose arms are named predicates — `$this->isImageAttribute($attribute) => …, default => …` — not a ternary on a raw `===` comparison; when the concept has no model/enum home, the predicate is a private method on the class.
22. Name each operand of a compound condition as a boolean before the `if` — `$isMdoc = …; $isApiCall = …; if ($isMdoc && ! $isApiCall)` — rather than inlining two method calls into one condition. When the operands all read the same object, add a named predicate to that object instead (`$invoice->isOverdue()`).

## PHP — naming

23. Name a variable that holds a map keyed by a field after that key (`xxxById`, `xxxByKey`) — the name tells the reader the structure at every later use. Applies to plain arrays and `keyBy(...)` results alike.
24. On a class that isn't a value object, a method returning a derived value is `getXxx()` (`getBirthdate()`); bare noun names are for VO properties (core rule *Value holders are `final readonly` with `public readonly` properties*).
25. Order parameters primary subject first, context/metadata after (`parse(string $dateValue, string $namespace)`). Name any variable for what it holds, not for its relation to the surrounding code — `$dateValue`, not `$value`; `$testsForThisShard`, not `$mine`. Name it after the model or class it holds; leading qualifiers may go when only one such model is in scope (`$membership` for an `OrganizationGroupMembership`) and stay when they tell two apart (`$organizationGroupIds` beside another kind of group id).
26. A variable or constant holding a measurement carries its unit (`$cellPaddingInPoints`, `TIMEOUT_IN_SECONDS`) — a bare `$padding` leaves the reader guessing px vs pt.

## PHP — ordering and structure

27. Order fields/array keys to mirror their source of truth (spec, API contract, referenced document); order constants and methods by lifecycle — success before failure, `markAsPublished()` before `markAsArchived()` — with `isXxx()` predicates ahead of the other methods, and mirror that order in the test file; separate inline-commented groups with blank lines so each comment's scope is unambiguous. When adding a case to a set that already exists in several files — enum, `match` arms, factory states, lang keys, tests — put it beside its closest sibling in every one of them, so the parallel files stay in the same order.
28. Add `#[Override]` to a method that overrides a parent's, importing the attribute with `use Override;` rather than writing `#[\Override]` inline.
29. Gate a minority case behind the domain predicate that names it (`if ($order->hasSubscription()) { ... }`). Don't run its helper on the main path and assign the return value unconditionally: the common path should read as the common path.

## Constants and literals

- A literal becomes a named constant when it is reused across classes or its name says something the value doesn't (`FALLBACK_PAPER_SIZE = 'A4'`, `COLUMN_WIDTH_DATETIME = 26`, `HISTORY_ITEM_COUNT`). A one-off entry in a per-class config array (a column width, a header label) stays a literal with a trailing comment (see the trailing-comment rule under *PHP — comments*) — a constant for it is churn.
- Status codes are `Response::HTTP_*` constants, never integer literals — in exceptions, responses, and `abort()` alike.

## Validation

- Order `FormRequest` methods by processing phase: `prepareForValidation()` → `rules()` → `failedValidation()` → accessor helpers.
- Read request input through the typed accessors — `$request->string('q')`, `->integer()`, `->boolean()`, `->enum('status', Status::class)`, `->collect('ids')` — not `$request->input()` followed by a cast.
- Don't scaffold optional hooks you won't use — no empty `authorize()` returning `true`.
- Start every field's rule list with `bail`, and put one rule per line.
- Express a conditional rule inline in the rules array (`Rule::prohibitedIf(...)`, `Rule::requiredIf(...)`, `bail`), not by wrapping the field's rules in `Rule::when()`.

## PHPDoc / typing

- **PHPDoc types state the real contract.** `list<T>` for zero-indexed sequential arrays; array-shape syntax (`array{id: int, fields?: list<...>}`) for structured associative arrays at boundaries — not bare `array` or `array<string, mixed>`.
- Re-index before returning a documented `list<T>` — `->all()`, `->filter()`, `array_filter()`, unsetting elements can preserve keys; call `->values()`/`array_values()` first so the annotation and runtime shape don't diverge.
- Add a one-line summary docblock to a method/class whose purpose isn't obvious from its name (domain/protocol logic, unfamiliar algorithms); skip it when the name says everything. A class docblock describes the class, never its callers — dependencies point inward.
- Type a factory parameter with the concrete factory class (`Model|ModelFactory`), not the generic `Factory<Model>`.
- Link the exact spec/RFC section when implementing a standard — on every related endpoint/class, not just the first. Keep references to internal PRs, spikes, and tickets out of code, though; those belong in the PR description, not a code comment. The one exception is the ticket link on a `TODO:`.

## Auth

- `Auth::user()` over `$request->user()` in controllers (IDE support), and only in presentation layers.
- No PHPDoc for `Auth::user()`'s return type — the framework stubs already resolve it.

## API Resources

- Call model methods and attributes through the resource proxy (`$this->isIssued()`), not `$this->resource->isIssued()`, and keep each key on one line.
- Order resource keys: own attributes, then relations, then the `can` permission map last.

## Models

- Order model members framework-first, then custom: casts → `booted()` → accessors/mutators (`Attribute`) → relations → scopes → other methods.
- Define query scopes with the `#[Scope]` attribute, not the legacy `scopeXxx()` method.
- No `@property`/`@property-read` PHPDoc block on a model — the IDE-helper stubs and casts already supply the types, so a hand-written block only drifts from the schema.

## Eloquent

- A query chain with more than one `where()` spans lines; a short collection or object chain stays on one line while it fits (`$users->pluck('name')->all()`). When a query or collection chain spans lines, put the receiver alone on the first line (`Model::query()`, `$users`) and every chained call on its own line below — not `Model::query()->where(...)` on line one with the rest wrapped beneath, and not `])->all()` hanging off a closing bracket.
- End a query at its terminal call (`->get()`) and assign the result; run collection transforms (`map()`, `mapWithKeys()`) on that variable in a separate statement, so the database query and the in-memory reshaping read apart.
- Order a query chain by clause: `with()` → `select()`/`addSelect()` (and scopes that only add a column) → `join()` → `where()`/filter scopes → `orderBy()`/`groupBy()` → the terminal call.

## Migrations

- Head a data/backfill migration with a comment stating why it's needed and what it does — the schema diff shows the columns, not the reason a one-off backfill exists. When it reshapes or canonicalizes an existing stored structure, show the before→after shape concretely in that comment (or the PR body), not just prose — a reviewer without context can't infer the transformation from words alone.
- Declare FK columns with `foreignId()`, not `unsignedBigInteger()`.

## Routing

- Register a single-action controller with the array callable `[Controller::class, '__invoke']`, not the bare class string.
- Routes that share a leading path segment go under one `Route::prefix('/tokens')` group instead of repeating the segment on each route.
- Build JSON responses with the `response()->json(...)` helper rather than instantiating `JsonResponse` by hand — applies in controllers and in response/exception classes that emit JSON.

## Queue / Job dispatch

- Prefer helper functions — `dispatch(new JobClass(...))`, `event(new EventClass(...))` — over the static `::dispatch()` form, for IDE/phpstan completion on constructor args.

## Config / env

- Parse, rebuild or compare a URL through `Illuminate\Support\Uri` (`Uri::of($url)->host()`, `->withHost()`, `->origin()` where the Laravel version has it), not `parse_url()` plus string concatenation of scheme, host and port.
