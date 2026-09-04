---
name: custom-laravel-coding
description: Applies Laravel backend coding conventions for PHP implementation and refactoring. Use when implementing or refactoring Laravel services, controllers, models, actions, or related backend application logic.
---

Keep changes consistent with existing project patterns unless asked to refactor. Touch only what the task needs — no drive-by renames, reformatting, or edits to unrelated classes; every changed line costs review attention.

The core rules below are what to hold in mind while writing. The long tail lives in [references/checklist.md](references/checklist.md) — the review gate enforces it, so don't try to hold it in mind; read it only when a rule's detail matters.

## Core rules

1. **Guard clauses over nesting.** Invert the condition and bail out first; don't wrap the main path in a positive `if`.
2. **`collect()` pipelines over `array_*` nesting.** `collect($items)->map(...)->filter(...)`, not inside-out `array_map`/`array_filter` expressions; a raw `array_*` call only when no collection equivalent exists.
3. **Reuse domain language.** Before writing a raw conditional on a domain concept (role, membership, status, capability), grep the relevant model for an existing predicate/accessor — `isXxx()`, `hasXxx()` — and use it. When none exists, add one to the model or enum (`PaymentMethod::isCard()`) instead of comparing cases inline at the call site:

    ```php
    // Bad — inline re-derivation
    if ($user?->organization_id === Organization::INTERNAL_ID && $user->organization->sso_enabled) { ... }

    // Good — reuse domain helpers
    if ($user?->isInternalUser() && Organization::getInternalOrganization()?->hasEnableSsoLogin()) { ... }
    ```

4. **Framework helpers over hand-rolled primitives.** `Illuminate\Filesystem\Filesystem` (`ensureDirectoryExists()`, `deleteDirectory()`), `Uri`, `Str`/`Arr`, collection helpers — not manual `scandir`/string/array fiddling. Applies in test setup/teardown too.
5. **No speculative abstraction.** Prefer a direct `match` or small map over a registry for dispatch you fully own; no interface/factory/registry for a single in-house caller; build the simple single-case version now and record the deferred design (trigger + intended approach) in the project's decision doc; collapse two types introduced in the same change that model the same thing.
6. **Value holders are `final readonly` with `public readonly` properties.** No getters that only return their backing field; reserve `final` for VO/DTO rather than blanket-applying it; a private field + accessor only when the accessor does real work (validation, derivation, formatting).
7. **Validation lives in a `FormRequest`, expressed as rules.** Look for the built-in rule (`json`, `min:1`, `bail`, `Rule::enum(...)`) before hand-rolling a check; never re-verify downstream what validation already guarantees.
8. **Exceptions: named constructors + boundary handling.** `throw DomainException::invalidRequest()` — the exception class owns message keys and status codes; catch expected domain failures at the controller/edge and map them to the spec'd error response instead of leaking a 500.
9. **Eloquent idioms.** Start from `::query()`; use model scopes and dedicated `whereXxx` methods; omit `->value` for enum values on cast columns (add the cast if missing); on a held instance, assign attributes + `->save()` — not a `where('id', ...)->update([...])` that reads as bulk; link relations with `->associate()`, not hand-set FKs; no `$fillable` — set attributes explicitly (in tests and seeders too, so `$fillable` can go), `->replicate()` when copying a record.
10. **Datetime columns cast `immutable_datetime` by default.** Reach for the mutable `datetime` cast only when a column genuinely needs in-place mutation.
11. **Bulk insert when creating multiple records**, chunked. `insert()` bypasses model events, casts, and timestamps — populate everything those hooks would have set, and keep the model hook and bulk path on the same strategy (e.g. UUID format):

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

            UserNotification::query()->insert($notificationsData->toArray());
        });
    ```

12. **Routing and auth.** Build URLs with `route()`, never path literals; prefer route-model binding + the `->can('ability', 'model')` route helper over ids in the request body re-resolved in the controller; resourceful method names (`index`, `show`, `store`, `update`, `destroy`) for CRUD endpoints — `__invoke` only for genuinely non-resourceful actions, and single-action controllers named verb + resource (`DuplicateEmailTemplateController`, not `EmailDuplicationController`).
13. **Naming.** One term and one spelling per concept — American English, the feature's user-facing name as the term for its identifiers, conventional acronym casing (`OAuth`, `ID`, `URL`). Put a class in a directory named for its kind, grouped by domain (`ValueObjects/`, `Enums/{Domain}/`). Name for the real conceptual boundary, not a convenient umbrella prefix.
14. **PHPDoc types state the real contract.** `list<T>` for zero-indexed sequential arrays; array-shape syntax (`array{id: int, fields?: list<...>}`) for structured associative arrays at boundaries — not bare `array` or `array<string, mixed>`.
15. **Enums are the single source of truth; UI strings go through `__()`.** Reference the enum in config, validation rules, casts, and `match` arms — a hardcoded copy of a value anywhere will drift. No hardcoded English literals in enums, resources, or Blade/JSX.
16. **A comment carries only what the code can't say.** Delete one that restates the code. The previous implementation belongs in git, a deferred design in the decision doc (core rule 5) — neither belongs in a comment. Never explain how a framework method works. Keep what a reader can't derive: why a line exists at all (`// for idempotency`), why a workaround is there and when it can go; when a comment describes a marker or format, show one real example value. Mark a deliberately temporary state "for now" and name the risk accepted until it changes. One line where one line covers it.

## Review gate (mandatory)

Changed PHP is not done until it has passed a style review. Before presenting or committing:

1. Review the diff — only the diff — against the Core rules above, [references/checklist.md](references/checklist.md), and, for test files, the `custom-laravel-writing-tests` skill.
2. For a non-trivial diff, offload the pass to Codex per the global Codex rules, pointing it at those files as its checklist. For a small diff, do the pass yourself in-session.
3. Fix the violations, then present.
