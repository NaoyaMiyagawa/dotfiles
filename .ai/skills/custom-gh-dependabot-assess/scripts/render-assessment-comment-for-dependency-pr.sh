#!/bin/zsh
# Render the assessment comment for a dependency-bump PR from the collector's
# evidence and a judgement, so the model that judges a PR returns a few fields
# of JSON instead of writing the comment, and the lines the review-kit app
# parses always come out in the same form.
#
# Usage: render-assessment-comment-for-dependency-pr.sh <evidence.json> <judgement.json> --model <model-id>
#        render-assessment-comment-for-dependency-pr.sh <evidence.json> --auto
#        --auto writes the judgement from the evidence alone. It is only valid
#        when a mechanical rule already set the level to High.
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
shift
while (( $# > 0 )); do
  case $1 in
    --auto) judgement_file='' ;;
    --model) model=$2; shift ;;
    *) judgement_file=$1 ;;
  esac
  shift
done

# Print a judgement for a PR whose level a mechanical rule already set to
# High: the failing job and its first error, or the advisory the bump adds.
# A cause recorded for the failure's fingerprint replaces the generic wording,
# so PRs that fail the same way share one explanation.
build_rule_based_judgement() {
  local fingerprint cause='{}'
  fingerprint=$(jq -r '.ci.failed[0].fingerprint // ""' "$evidence_file")
  [[ -n $fingerprint && -s $cache_dir/causes/$fingerprint.json ]] && cause=$(<"$cache_dir/causes/$fingerprint.json")

  jq --argjson cause "$cause" '
    (.ci.failed[0] // null) as $job
    | ([.packages[] | .name as $name | (.advisories.introduced // [])[] | "\(.id) affects \($name)"] | first // null) as $advisory
    | {
        level: "High",
        hold_reason: ($cause.fix // (if $advisory then $advisory
          else "`\($job.job)` has to pass: \($job.errors[0] // "see the job log" | ltrimstr(" ") | .[0:160])" end)),
        verdict: (if $advisory then "The bump introduces a known advisory: \($advisory)."
          else "CI is red and the bump caused it: `\($job.job)` fails on this commit and passes on `\(.base_branch)`. \($cause.cause // "")" end),
        packages: {},
        checks: []
      }' "$evidence_file"
}

# 1. Read the judgement, or build one from the evidence with --auto.
if [[ -n $judgement_file ]]; then
  judgement=$(<"$judgement_file")
else
  [[ $(jq -r '.floor' "$evidence_file") == High ]] || { print -u2 'render: --auto needs a High floor'; exit 1; }
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
datetime=$(TZ=Asia/Singapore date '+%Y-%m-%d %H:%M +08 (SGT)')
assessed_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
values=$(jq -n --argjson judgement "$judgement" --slurpfile evidence "$evidence_file" \
  --arg model "$model" --arg datetime "$datetime" --arg assessed_at "$assessed_at" '
  def badge: {"Low": "🟢", "Medium": "🟡", "High": "🔴"}[.];
  def mark: {"pass": "✅", "medium": "⚠️", "high": "❌", "na": "➖"}[.] // "➖";
  def bullets: if length == 0 then "  - **None**: nothing to report" else map("  - " + .) | join("\n") end;
  def category: (if .dev then "dev" else "prod" end) + (if .direct then " (direct)" else " (transitive)" end);
  def advisory_link: "[\(.id)](\(.url)) (\(.severity // .type))";
  def rule_label: {
    "advisory-introduced": "No new advisory or malware",
    "ci-red-bump-caused": "CI passes where the base branch passes",
    "advisory-lookup-failed": "Advisory lookup completed",
    "ci-red-unresolved": "No unexplained CI failure",
    "ci-incomplete": "CI finished",
    "ci-ecosystem-jobs-skipped": "CI ran the jobs for this ecosystem",
    "diff-outside-package-files": "Diff is package-manager files only",
    "lockfile-host-change": "Download hosts unchanged",
    "lockfile-install-code": "No new install-time code",
    "lockfile-duplicate-copy": "No second copy of a single-copy package",
    "downgrade": "Not a downgrade",
    "notes-missing": "Release notes found",
    "published-resource-changed": "Published Laravel files unchanged"
  }[.];

  $evidence[0] as $e
  | ($e.packages | map(select(.named)) | first // $e.packages[0]) as $main
  | ($judgement.packages // {}) as $judged
  | ([$e.packages[] | .name as $name | (.advisories.introduced // [])[] | "⛔ introduces \(advisory_link) in \($name)"]) as $introduced
  | ([$e.packages[] | (.advisories.fixed // [])[] | advisory_link]) as $fixed
  | ([$e.packages[] | .name as $name | .to as $to | (.advisories.still_open // [])[] | "⚠️ \(advisory_link) still open in \($name) \($to)"]) as $open
  | ($introduced
      + (if ($fixed | length) > 0 then ["🛡 fixes \($fixed | join(", ")) — \($judgement.exposure // "reachability not determinable from advisory")"] else [] end)
      + $open) as $security
  | {
      badge: ($judgement.level | badge),
      level: $judgement.level,
      recommendation: (if $judgement.level == "Low" then "merge"
        elif $judgement.level == "Medium" then "merge after checking \($judgement.check_target)"
        else "hold, \($judgement.hold_reason)" end),
      security_line: (if ($security | length) > 0 then "**Security:** " + ($security | join(" · ")) else "" end),
      verdict_reason: $judgement.verdict,
      checks_table: ([
          ($e.rules[] | "| \(.id | rule_label) | \(if .fired then (if .level == "High" then "❌" else "⚠️" end) else "✅" end) | \(if .fired then .evidence else "" end) |"),
          (($judgement.checks // [])[] | "| \(.check) | \(.result | mark) | \(.evidence // "") |")
        ] | join("\n")),
      category: ($main | category), package: $main.name, from: ($main.from // "new"), to: $main.to, bump: $main.bump,
      what_it_does: ("  - " + ($judged[$main.name].what_it_does // $main.description // "No description published")),
      where_used: ("  - " + (if ($main.usage.file_count // 0) == 0 then "No direct imports found"
        else "\($main.usage.file_count) files, e.g. \($main.usage.files | .[0:5] | map("`\(. | ltrimstr("./"))`") | join(", "))" end)),
      what_changed: ($judged[$main.name].what_changed // [] | bullets),
      risk_reasoning: ($judged[$main.name].risk // [] | bullets),
      direct_count: ($e.packages | map(select(.direct)) | length),
      major_count: ($e.packages | map(select(.direct and .bump == "major")) | length),
      minor_count: ($e.packages | map(select(.direct and .bump == "minor")) | length),
      patch_count: ($e.packages | map(select(.direct and .bump == "patch")) | length),
      indirect_count: ([$e.lockfile_changes.moved_total - ($e.packages | length), 0] | max),
      package_rows: ($e.packages | map("| \(category) | `\(.name)` \(.from // "new") → \(.to) | \(.bump) | \(.usage.file_count // 0) files | \(($judged[.name].level // "") | badge // "➖") |") | join("\n")),
      package_blocks: ($e.packages | map(select($judged[.name].what_changed != null)
        | "**`\(.name)` \(.from // "new") → \(.to)**\n- **What changed**:\n\($judged[.name].what_changed | bullets)\n- **Risk**:\n\($judged[.name].risk // [] | bullets)") | join("\n\n")),
      tool: "Claude Code", model: $model, datetime: $datetime,
      head_sha: $e.head_sha,
      verdict: {"Low": "safe", "Medium": "check", "High": "risky"}[$judgement.level],
      detail: ({
        verdict: {"Low": "safe", "Medium": "check", "High": "risky"}[$judgement.level],
        reason: ($judgement.verdict | .[0:300]),
        assessedAt: $assessed_at, modelLabel: $model, usageChecked: true, provider: "claude"
      } | tojson | @base64),
      template: (if ($e.packages | length) > 1 then "group" else "single" end)
    }')

# 4. Fill the template and print the comment.
body=$(<"$script_dir/../templates/$(jq -r '.template' <<<"$values").md")
for key in "${(@f)$(jq -r 'del(.template) | keys[]' <<<"$values")}"; do
  value=$(jq -r --arg key "$key" '.[$key] | tostring' <<<"$values")
  # A placeholder with nothing to say takes its whole line with it.
  [[ -z $value ]] && body=${body//"{{$key}}"$'\n'/}
  body=${body//"{{$key}}"/$value}
done

print -r -- "$body"
