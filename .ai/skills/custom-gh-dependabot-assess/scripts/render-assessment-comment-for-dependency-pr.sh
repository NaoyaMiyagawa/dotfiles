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
        rule_based: true,
        verdict: "\(.packages | map("`\(.name)`") | join(", ")) runs only in lint, tests or local development tooling. No runtime file imports it, CI passed, and every check is green.",
        packages: {},
        checks: [{check: "Dev-only package", result: "pass", evidence: "Used only in lint, tests or local tooling; no runtime import"}]
      }
      elif $advisory then {
        level: "High", rule_based: true,
        hold_reason: $advisory,
        verdict: "The bump introduces a known advisory: \($advisory).",
        packages: {}, checks: []
      }
      else {
        level: "High", rule_based: true,
        hold_reason: "`\($job.job)` has to pass first",
        verdict: "CI fails because of the bump: `\($job.job)` fails on this commit and passes on `\(.base_branch)`.",
        to_check: [{
          what: "CI failed after the bump",
          finding: ($cause.cause // "`\($job.job)` fails here and passes on `\(.base_branch)`: \($job.errors[0] // "see the job log" | ltrimstr(" ") | .[0:200])"),
          how: ($cause.fix // "Open the job log, then fix the failure on this branch or hold the bump.")
        }],
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
  def category: (if .dev then "dev" else "prod" end) + (if .test_only then " (test-only)" elif .direct then " (direct)" else " (transitive)" end);
  def advisory_link: "[\(.id)](\(.url)) (\(.severity // .type))";
  # What a fired rule says in the checks table, ahead of its evidence.
  def rule_failure: {
    "advisory-introduced": "New advisory or malware",
    "ci-red-bump-caused": "CI failed after the bump",
    "advisory-lookup-failed": "Advisory lookup failed",
    "ci-red-unresolved": "Unexplained failure",
    "ci-red-network": "Network error",
    "ci-incomplete": "CI absent or cancelled",
    "ci-ecosystem-jobs-skipped": "The jobs for this ecosystem did not run",
    "diff-outside-package-files": "Non-package files changed",
    "lockfile-host-change": "Download host changed",
    "lockfile-install-code": "New install-time code",
    "lockfile-duplicate-copy": "Duplicate package copy",
    "downgrade": "Downgrade",
    "notes-missing": "No release notes",
    "notes-incomplete": "Incomplete release notes",
    "published-resource-changed": "Upstream changed"
  }[.];
  # What a person does about a fired rule when no judge said it better.
  def rule_action: {
    "advisory-introduced": "Hold the bump until a version without the advisory is out.",
    "ci-red-bump-caused": "Open the job log, fix the failure on this branch or hold the bump.",
    "advisory-lookup-failed": "Run the assessment again; the advisory database did not answer.",
    "ci-red-unresolved": "Check whether the job fails on the base branch for the same reason, then re-run it.",
    "ci-red-network": "Re-run the job; safe once it passes.",
    "ci-incomplete": "Wait for CI or re-run the cancelled jobs, then assess again.",
    "ci-ecosystem-jobs-skipped": "Run the build and tests for this ecosystem before merging.",
    "diff-outside-package-files": "Review these files as code; this assessment covers the packages only.",
    "lockfile-host-change": "Confirm the new host is a registry you trust.",
    "lockfile-install-code": "Read the install script of the package before merging.",
    "lockfile-duplicate-copy": "Check the app still loads one copy, or dedupe the lockfile.",
    "downgrade": "Confirm the downgrade is intended.",
    "notes-missing": "Read the upstream commits for the range; no release notes were found.",
    "notes-incomplete": "Skim the upstream releases page for the range; the lines left out carried no breaking keyword. Safe if none touches a feature this app uses.",
    "published-resource-changed": "Compare your copy of each file with the upstream change."
  }[.];
  # The mechanical rules grouped into the areas a reader checks, each with the
  # sentence shown when every rule in it passed.
  def areas($e): [
    {area: "Security", rules: ["advisory-introduced", "advisory-lookup-failed"],
     passed: "No new advisory or malware"},
    {area: "CI", rules: ["ci-red-bump-caused", "ci-red-unresolved", "ci-red-network", "ci-incomplete", "ci-ecosystem-jobs-skipped"],
     passed: "\($e.ci.passed) jobs passed"},
    {area: "Files and lockfile", rules: ["diff-outside-package-files", "lockfile-host-change", "lockfile-install-code", "lockfile-duplicate-copy"],
     passed: ((if $e.formatter_only then "Package files and formatter output only" else "Package files only" end)
       + "; no new download host, install script or duplicate copy")},
    {area: "Release notes", rules: ["downgrade", "notes-missing", "notes-incomplete"],
     passed: (if $e.tier != "patch" and any($e.packages[]; .test_only | not) then "Read in full for the whole range; not a downgrade" else "Not needed for this bump; not a downgrade" end)},
    {area: "Published Laravel files", rules: ["published-resource-changed"],
     passed: "No upstream change to a file this repo published"}
  ];
  # One row per area, then the rows the judge added, with the rows that need
  # attention first. An area whose rules do not apply to this PR is left out.
  # A judge row named after an area is folded into that area, so no topic
  # shows twice.
  def check_rows($e; $judgement):
    [$judgement.checks // [] | .[] | select(.result != "na")] as $judged
    | [areas($e)[].area] as $area_names
    | [ ($judged[] | select(.check | IN($area_names[]) | not)
          | {rank: ({"high": 0, "medium": 1}[.result] // 2), row: "| \(.check | cell) | \(.result | mark) | \(.evidence // "" | cell) |"}),
        (areas($e)[] | . as $area
          | [$e.rules[] | select((.id | IN($area.rules[])) and (.not_applicable | not))] as $rules
          | [$judged[] | select(.check == $area.area)] as $added
          | select(($rules | length) > 0 or ($added | length) > 0)
          | ($rules | map(select(.fired))) as $fired
          | ([($fired[] | if .level == "High" then 0 else 1 end), ($added[] | {"high": 0, "medium": 1}[.result] // 2), 2] | min) as $rank
          | {rank: $rank,
             row: "| \($area.area) | \(["❌", "⚠️", "✅"][$rank]) | \(
               [ (if ($fired | length) > 0 then $fired[] | (.id | rule_failure) + (if .evidence != "" then ": \(.evidence | cell)" else "" end)
                  elif ($rules | length) > 0 then $area.passed else empty end),
                 ($added[] | .evidence // "" | cell | select(. != "")) ] | join("<br>")) |"})
      ] | sort_by(.rank) | map("  " + .row) | join("\n");

  $evidence[0] as $e
  | ($e.packages | map(select(.named)) | first // $e.packages[0]) as $main
  | ($judgement.packages // {}) as $judged
  | ([$e.packages[] | .name as $name | (.advisories.introduced // [])[] | "⛔ introduces \(advisory_link) in \($name)"]) as $introduced
  | ([$e.packages[] | .name as $name | (.advisories.fixed // [])[] | "\(advisory_link) in `\($name)`"]) as $fixed
  | ([$e.packages[] | .name as $name | .to as $to | (.advisories.still_open // [])[] | "⚠️ \(advisory_link) still open in \($name) \($to)"]) as $open
  | ($introduced
      + (if ($fixed | length) > 0 then ["🛡 fixes \($fixed | join(", ")) — \($judgement.exposure // "the advisory does not list the affected functions" | one_line)"] else [] end)
      + $open) as $security
  | {"Low": "safe", "Medium": "check", "High": "risky"}[$judgement.level] as $verdict
  | {
      badge: ($judgement.level | badge),
      level: $judgement.level,
      recommendation: (if $judgement.level == "Low" then "merge"
        elif $judgement.level == "Medium" then (if (($judgement.to_check // []) | length) > 1 then "merge after checking the \($judgement.to_check | length) items below" else "merge after checking \($judgement.check_target | one_line)" end)
        else "hold, \($judgement.hold_reason | one_line)" end),
      security_line: (if ($security | length) > 0 then "**Security:** " + ($security | join(" · ")) else "" end),
      verdict_reason: ($judgement.verdict | one_line),
      # What to do before merging: the steps the judgement gives. A judgement
      # built from the rules alone gets a fixed step for each other fired rule.
      to_check: (
        ([($judgement.to_check // [])[] | "- **\(.what | one_line):** \(.finding // "" | one_line) **Check:** \(.how // "" | one_line)"]
         + (if $judgement.rule_based or (($judgement.to_check // []) | length) == 0 then
             [$e.rules[] | select(.fired and ((.id | IN("ci-red-bump-caused", "advisory-introduced") | not) or (($judgement.to_check // []) | length) == 0))
               | "- **\(.id | rule_failure):** \(if .evidence != "" then "\(.evidence | one_line). " else "" end)**Check:** \(.id | rule_action)"]
           else [] end)) as $steps
        | if $judgement.level == "Low" or ($steps | length) == 0 then ""
          else "\n**Before merging:**\n" + ($steps | join("\n")) end),
      checks_table: check_rows($e; $judgement),
      category: ($main | category), package: $main.name, from: ($main.from // "new"), to: $main.to, bump: $main.bump,
      what_it_does: ("  - " + ($judged[$main.name].what_it_does // $main.description // "No description published" | one_line)),
      where_used: ("  - " + (if ($main.usage.file_count // 0) == 0 then "No direct imports found"
        else "\($main.usage.file_count) file\(if $main.usage.file_count == 1 then "" else "s" end)\(if $main.usage.file_count <= 5 then ": " else ", e.g. " end)\($main.usage.files | .[0:5] | map("`\(. | ltrimstr("./"))`") | join(", "))" end)),
      what_changed: ($judged[$main.name].what_changed // [] | bullets),
      risk_reasoning: ($judged[$main.name].risk // [] | bullets),
      direct_count: ($e.packages | map(select(.direct)) | length),
      major_count: ($e.packages | map(select(.direct and .bump == "major")) | length),
      minor_count: ($e.packages | map(select(.direct and .bump == "minor")) | length),
      patch_count: ($e.packages | map(select(.direct and .bump == "patch")) | length),
      indirect_count: ([$e.lockfile_changes.moved_total - ($e.packages | length), 0] | max),
      # A package the judge read and did not single out is Low. A judgement
      # built from the rules alone read no package, so it shows a dash.
      package_rows: ($e.packages | map("| \(category) | `\(.name)` \(.from // "new") → \(.to) | \(.bump) | \(.usage.file_count // 0) file\(if .usage.file_count == 1 then "" else "s" end) | \(($judged[.name].level // (if $judgement.level == "Low" or ($judgement.rule_based | not) then "Low" else "" end)) | badge // "➖") |") | join("\n")),
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
