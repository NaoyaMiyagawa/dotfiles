# Manual Dependency PR Assessment (Fallback)

Read this only when `collect-evidence-for-dependency-pr.sh` reports `"supported": false` (unsupported lockfile, Actions-only bump, or custom manifest) or when filling an `unknown` check by hand.

## Sections

**What it does.** One or two sentences from the registry description or README. Say what the app relies on it for, not what the marketing page says.

**Where it's used.** Category decides the method:
- `direct:production` — grep imports. npm: package name in `import`/`require`. Composer: PSR-4 namespace from `vendor/<pkg>/composer.json` `autoload.psr-4`, not the package name (`spatie/laravel-permission` → `Spatie\Permission`). For Laravel packages also grep facades, auto-discovered providers, and `config/*.php`; write "no direct imports" rather than "unused". Map hits to pages by route entry when derivable; list up to 10 paths, then "+N more across `<dirs>`".
- `direct:development` — grep the same way; name files and pipeline stage (lint, test, build), and flag any runtime import of a dev-only dependency.
- `indirect` — "required by X, Y" from the lockfile. No grep.
- GitHub Actions — workflow files under `.github/` referencing the action.

**What changed.** Use Dependabot's PR body first. When truncated, absent, or incomplete for the range, run `gh api repos/<owner>/<repo>/releases`. For major bumps also read upstream `UPGRADE.md`/`CHANGELOG.md` at the new tag via `https://raw.githubusercontent.com/<owner>/<repo>/<tag>/<path>`. Security PRs: `gh api /advisories/<GHSA>` for `severity` and `vulnerabilities[].vulnerable_functions` (if empty, write "reachability not determinable from advisory").

**Risk.** Run these checks against the PR head:
- **Usage of changed APIs**: grep every removed, renamed, or behaviour-changed API from release notes; read hits to exclude already-adapted calls.
- **Diff scope**: read hunks of `gh pr diff <n>`. Package-manager changes are manifest version lines, lockfile entries, and Actions `uses:`. Note everything else, plus every direct dependency moved in the lockfile and any changed `resolved`/`dist.url` host.
- **Runtime floor**: compare new `engines.node`, `require.php`, `ext-*`, peer deps, and runner against repo config (`.nvmrc`, `engines`, `config.platform.php`, CI/Docker, `runs-on`).
- **Advisories on the new version**: `gh api --paginate '/advisories?ecosystem=<npm|composer|actions>&affects=<package>@<new version>'` and old version, plus `&type=malware` for both. Failed lookup ≠ empty list.
- **Install-time code**: new `"hasInstallScript": true` (npm), `requiresBuild` (pnpm), or `"type": "composer-plugin"` (Composer).
- **Entry points** (npm, minor/major, runtime/build): `npm view <package>@<version> exports type main --json` for both versions; check removed imported subpaths and `type: "module"` switches.
- **Single-copy packages**: second resolved copy of `react`, `react-dom`, router, or shared state/UI lib.
- **Published Laravel resources** (Composer, minor/major): if repo holds `config/<name>.php`, `resources/views/vendor/<name>/`, or copied migrations, check `gh api repos/<owner>/<repo>/compare/<old>...<new> --jq '.files[].filename'`.
- **What CI ran**: from `statusCheckRollup`, verify jobs for the bumped ecosystem ran (a re-run pass overrides an earlier failure on the same commit).
- **Past decisions**: `.github/dependabot.yml` ignores and exact-version pins in manifests.

## Risk rules

Check High → Medium → Low; first match wins. A 0.x minor bump counts as major. **Breaking note** = removed, renamed, or behaviour/default/schema change. **Test-only dev dependency** runs only in lint/tests/local dev (not bundler/compiler/TS/CSS) and skips usage and release-note rules. **Formatter output** by a bumped formatter/linter counts as part of the bump.

🔴 **High** (`risky`):
- PR head still calls a removed/renamed API or relies on broken behaviour (verified grep hit).
- CI is red on the assessed commit and caused by the bump (passes on base or log names package; exclude pure network faults).
- Drops a runtime/extension/runner the repo uses, or leaves a required peer dep unmet.
- Advisory or malware record affects new version and not old.
- Repo imports a subpath the new version no longer exports.

🟡 **Medium** (`check`):
- Unresolved breaking note affecting a default/behaviour runtime or build code may rely on (e.g. via config, facade, dynamic call).
- Diff contains non-package-manager changes other than formatter output.
- Lockfile changes registry/download host, adds install-time code, or adds a second copy of a single-copy package.
- Range changes a published Laravel config, view, or migration.
- Switches to ESM-only and repo uses `require`.
- Release notes missing or incomplete for a minor/major bump.
- Downgrade.
- CI job passing on base failed on a network fault alone (target: re-run job), OR CI is absent/pending/blocked/cancelled/pre-existing red/skipped ecosystem jobs.
- Advisory lookup failed.

🟢 **Low** (`safe`): no High/Medium matched AND diff is package-manager/formatter only, ecosystem CI is green, no breaking note reaches PR head, and no new advisory. If any Low condition fails, level is Medium.

Recommendation: Low → `merge` · Medium → `merge after checking <concrete target>` · High → `hold, <what has to change first>`.
Group PR: Risk = highest across direct packages; per-package detail blocks only for major/breaking packages.

### Security line

Reported beside level (only newly introduced advisories change level):
- Fixes: `**Security:** 🛡 fixes <linked GHSA> (<severity>) — <exposure>` (`vulnerable code used in <path>, merge soon` | `no use of the vulnerable code found` | `reachability not determinable from advisory`).
- Still open: `**Security:** ⚠️ <linked GHSA> (<severity>) still open in <new version>`.
- Introduces: `**Security:** ⛔ introduces <linked GHSA> (<severity>) in <new version>`.

## Comment rules (manual rendering)

- Two visible lines (`**Risk:** <badge> **<Low|Medium|High>** — <recommendation>` and `**Summary:**`), optional `**Security:**`, one `<details>` fold, footer, review-kit markers, and `<!-- dependabot-assessment -->` as the last line. No `#` headings. Reassess drops any `**Gate:**` line.
- Inside fold: start with `- **Verdict**: <rule that set level>` (also used as `reason` in `{{detail}}`), then bold-label bullets (`- **Risk**:`) with nested bold-title sub-bullets (`  - **Breaking changes**: ...`).
- Write as if first assessment (never reference prior assessments in comment).
- `{{category}}`: `prod (direct)` | `dev (direct)` | `prod (transitive)` | `dev (transitive)` | `ci`.
- `{{checks_table}}`: one row per check with ✅ / ⚠️ / ❌ / ➖ and brief evidence. Mention CI only when a CI rule set the level. Single PR <60 lines, group <100.
- Footer: `<sub>Posted by {tool} ({model}) at {SGT}</sub>` (see `custom-gh-comment-footer`), placed directly above the review-kit lines.
- Review-kit lines directly above `<!-- dependabot-assessment -->`: `{{head_sha}}` (40-char), `{{verdict}}` (`safe`/`check`/`risky`), and `{{detail}}` (single-line base64 of `{"verdict":"...","reason":"<under 300 chars>","assessedAt":"<ISO UTC>","modelLabel":"...","usageChecked":true|false,"provider":"claude|codex"}`).
