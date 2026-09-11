# Tooling candidates — rules to retire into Pint / PHPStan / Rector

Migration map for enforcing mechanical rules in the work repo's toolchain. When a rule lands in tooling there, delete it from the skill/checklist and drop its row here. The daily retro appends a row here when a correction is mechanically checkable, instead of adding prose to the skill.

Enforcement names below are candidates to verify against current tool docs, not confirmed configs.

| Rule | Candidate enforcement |
| --- | --- |
| `use` imports over inline FQNs | Pint: `global_namespace_import` / `fully_qualified_strict_types` |
| `$x === null` over `is_null()` | Pint (php-cs-fixer `is_null` fixer) |
| Strict `in_array`/`array_search` | php-cs-fixer `strict_param` (risky) or phpstan-strict-rules |
| `#[Override]` on overriding methods | PHPStan `checkMissingOverrideMethodAttribute` / Rector `AddOverrideAttributeToOverriddenMethodsRector` |
| Returned `list<T>` actually re-indexed | PHPStan list-type checking at high level |
| Multiline constructor args | php-cs-fixer `method_argument_space` (partial coverage) |
| String interpolation over concatenation | custom Rector rule |
| No `$fillable` on models | small custom PHPStan rule |
| Start queries from `::query()` | small custom PHPStan/Larastan rule |
| `immutable_datetime` cast default | small custom PHPStan rule over model casts |
| `#[Scope]` over legacy `scopeXxx()` | Rector Laravel set or custom rule |
| `Response::HTTP_*` constants over integer HTTP status-code literals | custom Rector/PHPStan rule flagging int literals in `response()`/`abort()`/`HttpException`/`setStatusCode` args — no stock fixer |
| Comment line length ceiling (~120–130 chars; no early wrap at 80) | custom rule/formatter over comment tokens — flags the upper bound; reflowing over-wrapped comments needs a custom fixer, no stock fixer |
| Ban `->sole()` (prefer `firstOrFail()`) | small custom PHPStan/Larastan rule flagging `sole(` method calls |
| Multi-line arrow fn → classic closure (checklist, *PHP — formatting and syntax*) | custom Rector/php-cs-fixer rule flagging an `fn (...) =>` whose token span crosses a newline |
| One case per line in a multi-case `match` arm | custom Rector/php-cs-fixer rule flagging a `match` arm whose case list holds more than one case on a line |
| `->__toString()` over a `(string)` cast | custom Rector rule rewriting `(string) $expr` where the operand is `Stringable` |
| No `@property`/`@property-read` PHPDoc on models | small custom PHPStan rule flagging `@property` tags in class docblocks under `Models/` |
| Test-body `//` comments other than `Arrange`/`Act`/`Assert` carry a `- ` prefix (writing-tests skill, core rule *AAA markers in every case you write*) | custom Pint/php-cs-fixer rule over comment tokens inside `test()`/`it()` closures: flag `// text` that is not one of the three markers and does not start with `// - ` |
| Request URLs in tests built with `route()`, never a path literal (writing-tests skill, core rule *Feature request shape*) | custom PHPStan rule over test files: flag a string literal starting with `/` as the first arg of `get()`/`post()`/`postJson()`/… |
| No raw `*_id` key in a factory attribute array — use a `forXxx()` state (writing-tests checklist, *Factory*) | custom PHPStan rule over test files: flag array keys ending in `_id` passed to `::factory()`/`->create*()`/`->state()` |
| One chained call per line in a request chain — no `])->assertXxx()` on the closing line (writing-tests skill, core rule *Feature request shape*) | Pint/php-cs-fixer `method_chaining_indentation` plus a custom check that a `->assert*(` call follows a newline |
| Test file basename maps 1:1 to a production class (`XxxTest.php` ↔ class `Xxx`) (writing-tests skill, core rule *One test file per production class, named verbatim after it*) | small script in CI: for each `*Test.php`, assert a class with the stripped name exists in the autoload map |
