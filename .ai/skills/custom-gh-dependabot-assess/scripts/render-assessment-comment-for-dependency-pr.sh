#!/bin/zsh
# Render the assessment comment for a dependency-bump PR from the collector's
# evidence and a judgement, so the model that judges a PR returns a few fields
# of JSON instead of writing the comment, and the lines the review-kit app
# parses always come out in the same form.
#
# Usage: render-assessment-comment-for-dependency-pr.sh <evidence.json> <judgement.json> --model <label> [--provider <claude|codex>]
#        render-assessment-comment-for-dependency-pr.sh <evidence.json> --auto
#        --auto writes the judgement from the evidence alone. It is only valid
#        when the evidence says `"auto": true`: a mechanical rule already set
#        the level to High, or the PR bumps test-only dev dependencies and
#        passed every mechanical rule.
#
# Steps:
#   1. Read the judgement, or build one from the evidence with --auto.
#   2. Refuse a judgement the evidence does not allow.
#   3. Work out every template value.
#   4. Fill the template and print the comment.
#
# Exit 0 means stdout is a complete comment body, ready for
# `gh pr comment --body-file`. A judgement below the evidence's floor, or one
# missing its check target or hold reason, exits 1 and prints nothing.
set -euo pipefail

script_dir=${0:A:h}
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/dependabot-assess

evidence_file=$1
judgement_file=''
model='rule-based, no model'
provider=claude
shift
while (( $# > 0 )); do
  case $1 in
    --auto) judgement_file='' ;;
    --model) model=$2; shift ;;
    --provider) provider=$2; shift ;;
    *) judgement_file=$1 ;;
  esac
  shift
done

# Print a judgement for a PR the evidence settles without a model.
# High: the failing job the bump caused and its first error, or the advisory
# the bump adds. A cause recorded for the failure's fingerprint replaces the
# generic wording, so PRs that fail the same way share one explanation.
# Low: the test-only dev dependencies that passed every mechanical rule.
build_rule_based_judgement() {
  local fingerprint cause='{}'
  fingerprint=$(jq -r '[.ci.failed[] | select(.base_branch_result == "passed" and (.network_only | not)) | .fingerprint // empty] | first // ""' "$evidence_file")
  [[ -n $fingerprint && -s $cache_dir/causes/$fingerprint.json ]] && cause=$(<"$cache_dir/causes/$fingerprint.json")

  jq --argjson cause "$cause" '
    ([.ci.failed[] | select(.base_branch_result == "passed" and (.network_only | not))] | first // null) as $job
    | ([.packages[] | .name as $name | (.advisories.introduced // [])[] | "\(.id) affects \($name)"] | first // null) as $advisory
    | if .floor != "High" then {
        level: "Low",
        verdict: "No rule fired: \(.packages | map("`\(.name)`") | join(", ")) runs only in lint, tests or local development tooling, no runtime file imports it, CI ran the \(.ecosystem) jobs green, and every mechanical check passed.",
        packages: {},
        checks: [{check: "Test-only dev dependency", result: "pass", evidence: "on the test-only list, no runtime import"}]
      }
      elif $advisory then {
        level: "High",
        hold_reason: $advisory,
        verdict: "The bump introduces a known advisory: \($advisory).",
        packages: {}, checks: []
      }
      else {
        level: "High",
        hold_reason: ($cause.fix // "`\($job.job)` has to pass: \($job.errors[0] // "see the job log" | ltrimstr(" ") | .[0:160])"),
        verdict: "CI is red and the bump caused it: `\($job.job)` fails on this commit and passes on `\(.base_branch)`. \($cause.cause // "")",
        packages: {}, checks: []
      } end' "$evidence_file"
}

# 1. Read the judgement, or build one from the evidence with --auto.
# A judgement file may hold one judgement, or several keyed by PR number.
if [[ -n $judgement_file ]]; then
  judgement=$(jq --slurpfile evidence "$evidence_file" 'if has("level") then . else .[$evidence[0].pr | tostring] end' "$judgement_file")
else
  [[ $(jq -r '.auto' "$evidence_file") == true ]] || { print -u2 'render: --auto needs evidence with "auto": true'; exit 1; }
  judgement=$(build_rule_based_judgement)
fi

# 2. Refuse a judgement the evidence does not allow.
# The floor comes from mechanical rules; release notes and PR text reach the
# judge, so the judge may raise the level but never lower it.
jq -en --argjson judgement "$judgement" --slurpfile evidence "$evidence_file" '
  def rank: {"Low": 0, "Medium": 1, "High": 2}[.];
  ($judgement.level | rank) != null
  and ($judgement.level | rank) >= ($evidence[0].floor | rank)
  and ($judgement.verdict // "" | length) > 0
  and ($judgement.level != "Medium" or ($judgement.check_target // "" | length) > 0)
  and ($judgement.level != "High" or ($judgement.hold_reason // "" | length) > 0)
' >/dev/null || { print -u2 'render: judgement is below the floor, or lacks a verdict, check_target or hold_reason'; exit 1; }

# 3. Work out every template value.
# Judgement text and CI log lines are untrusted: one_line keeps them from
# breaking the parsed Risk line, and cell from breaking the checks table.
datetime=$(TZ=Asia/Singapore date '+%Y-%m-%d %H:%M +08 (SGT)')
assessed_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
values=$(jq -n --argjson judgement "$judgement" --slurpfile evidence "$evidence_file" \
  --arg model "$model" --arg provider "$provider" --arg datetime "$datetime" --arg assessed_at "$assessed_at" '
  def badge: {"Low": "🟢", "Medium": "🟡", "High": "🔴"}[.];
  def mark: {"pass": "✅", "medium": "⚠️", "high": "❌", "na": "➖"}[.] // "➖";
  def one_line: tostring | gsub("\\s*[\\r\\n]+\\s*"; " ");
  def cell: one_line | gsub("\\|"; "\\|");
  def bullets: if length == 0 then "  - **None**: nothing to report" else map("  - " + one_line) | join("\n") end;
  def category: (if .dev then "dev" else "prod" end) + (if .direct then " (direct)" else " (transitive)" end);
  def advisory_link: "[\(.id)](\(.url)) (\(.severity // .type))";
  def rule_label: {
    "advisory-introduced": "No new advisory or malware",
    "ci-red-bump-caused": "CI passes where the base branch passes",
    "advisory-lookup-failed": "Advisory lookup completed",
    "ci-red-unresolved": "No unexplained CI failure",
    "ci-red-network": "No CI job failed on a network error",
    "ci-incomplete": "CI finished",
    "ci-ecosystem-jobs-skipped": "CI ran the jobs for this ecosystem",
    "diff-outside-package-files": "Diff is package-manager files only",
    "lockfile-host-change": "Download hosts unchanged",
    "lockfile-install-code": "No new install-time code",
    "lockfile-duplicate-copy": "No second copy of a single-copy package",
    "downgrade": "Not a downgrade",
    "notes-missing": "Release notes found",
    "notes-incomplete": "Release notes cover the whole range",
    "published-resource-changed": "Published Laravel files unchanged"
  }[.];

  $evidence[0] as $e
  | ($e.packages | map(select(.named)) | first // $e.packages[0]) as $main
  | ($judgement.packages // {}) as $judged
  | ([$e.packages[] | .name as $name | (.advisories.introduced // [])[] | "⛔ introduces \(advisory_link) in \($name)"]) as $introduced
  | ([$e.packages[] | (.advisories.fixed // [])[] | advisory_link]) as $fixed
  | ([$e.packages[] | .name as $name | .to as $to | (.advisories.still_open // [])[] | "⚠️ \(advisory_link) still open in \($name) \($to)"]) as $open
  | ($introduced
      + (if ($fixed | length) > 0 then ["🛡 fixes \($fixed | join(", ")) — \($judgement.exposure // "reachability not determinable from advisory" | one_line)"] else [] end)
      + $open) as $security
  | {"Low": "safe", "Medium": "check", "High": "risky"}[$judgement.level] as $verdict
  | {
      badge: ($judgement.level | badge),
      level: $judgement.level,
      recommendation: (if $judgement.level == "Low" then "merge"
        elif $judgement.level == "Medium" then "merge after checking \($judgement.check_target | one_line)"
        else "hold, \($judgement.hold_reason | one_line)" end),
      security_line: (if ($security | length) > 0 then "**Security:** " + ($security | join(" · ")) else "" end),
      verdict_reason: ($judgement.verdict | one_line),
      checks_table: ([
          ($e.rules[] | "| \(.id | rule_label) | \(if .not_applicable then "➖" elif .fired then (if .level == "High" then "❌" else "⚠️" end) else "✅" end) | \(if .fired then .evidence | cell else "" end) |"),
          (if $e.formatter_only then "| Other files are formatter output | ✅ | removed and added lines match once whitespace, quotes and order are ignored |" else empty end),
          (($judgement.checks // [])[] | "| \(.check | cell) | \(.result | mark) | \(.evidence // "" | cell) |")
        ] | join("\n")),
      category: ($main | category), package: $main.name, from: ($main.from // "new"), to: $main.to, bump: $main.bump,
      what_it_does: ("  - " + ($judged[$main.name].what_it_does // $main.description // "No description published" | one_line)),
      where_used: ("  - " + (if ($main.usage.file_count // 0) == 0 then "No direct imports found"
        else "\($main.usage.file_count) files, e.g. \($main.usage.files | .[0:5] | map("`\(. | ltrimstr("./"))`") | join(", "))" end)),
      what_changed: ($judged[$main.name].what_changed // [] | bullets),
      risk_reasoning: ($judged[$main.name].risk // [] | bullets),
      direct_count: ($e.packages | map(select(.direct)) | length),
      major_count: ($e.packages | map(select(.direct and .bump == "major")) | length),
      minor_count: ($e.packages | map(select(.direct and .bump == "minor")) | length),
      patch_count: ($e.packages | map(select(.direct and .bump == "patch")) | length),
      indirect_count: ([$e.lockfile_changes.moved_total - ($e.packages | length), 0] | max),
      # A package the judge gave no level of its own is Low when the PR is.
      package_rows: ($e.packages | map("| \(category) | `\(.name)` \(.from // "new") → \(.to) | \(.bump) | \(.usage.file_count // 0) files | \(($judged[.name].level // (if $judgement.level == "Low" then "Low" else "" end)) | badge // "➖") |") | join("\n")),
      package_blocks: ($e.packages | map(select($judged[.name].what_changed != null)
        | "**`\(.name)` \(.from // "new") → \(.to)**\n- **What changed**:\n\($judged[.name].what_changed | bullets)\n- **Risk**:\n\($judged[.name].risk // [] | bullets)") | join("\n\n")),
      tool: (if $provider == "codex" then "Codex" else "Claude Code" end), model: $model, datetime: $datetime,
      head_sha: $e.head_sha,
      verdict: $verdict,
      detail: ({
        verdict: $verdict,
        reason: ($judgement.verdict | one_line | .[0:300]),
        assessedAt: $assessed_at, modelLabel: $model, usageChecked: true, provider: $provider
      }
      # The security status as data, so a reader need not parse the comment.
      + (if ($introduced | length) > 0 then {security: "introduces"} elif ($fixed | length) > 0 then {security: "fixes"}
         elif ($open | length) > 0 then {security: "open"} else {} end)
      | tojson | @base64),
      template: (if ($e.packages | length) > 1 then "group" else "single" end)
    }')

# 4. Fill the template and print the comment.
# Every placeholder is replaced in one pass, so text that happens to hold
# "{{name}}" is never expanded a second time. A line that is only a
# placeholder with nothing to say is dropped whole.
print -u2 -- '--------- Result ---------'
jq -rn --argjson values "$values" --rawfile template "$script_dir/../templates/$(jq -r '.template' <<<"$values").md" '
  $template | rtrimstr("\n") | split("\n")
  | map(select(((capture("^\\{\\{(?<key>[a-z_]+)\\}\\}$").key as $key | $values[$key] == "") // false) | not))
  | map(gsub("\\{\\{(?<key>[a-z_]+)\\}\\}"; $values[.key] | tostring))
  | join("\n")'
