# Tooling candidates — rules to retire into Pint / PHPStan / Rector

Migration map for enforcing mechanical rules in the work repo's toolchain. When a rule lands in tooling there, delete it from the skill/checklist and drop its row here. The daily retro appends a row here when a correction is mechanically checkable, instead of adding prose to the skill.

Enforcement names below are candidates to verify against current tool docs, not confirmed configs.

| Rule | Candidate enforcement |
| --- | --- |
| `use` imports over inline FQNs | Pint: `global_namespace_import` / `fully_qualified_strict_types` |
| `$x === null` over `is_null()` | Pint (php-cs-fixer `is_null` fixer) |
| Strict `in_array`/`array_search` | php-cs-fixer `strict_param` (risky) or phpstan-strict-rules |
| `#[\Override]` on overriding methods | PHPStan `checkMissingOverrideMethodAttribute` / Rector `AddOverrideAttributeToOverriddenMethodsRector` |
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
