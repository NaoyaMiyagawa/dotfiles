#!/bin/zsh
# Have a model judge what the collector could not settle for one or more
# dependency-bump PRs, in a single call that has no tools: the model reads
# judge.md and a trimmed copy of each evidence file and answers in JSON. A
# call without tools costs a fraction of an agent run, and release notes it
# reads cannot make it do anything but answer.
#
# Usage: judge-dependency-prs.sh --model <haiku|sonnet> --out-dir <dir> <evidence.json>...
#        judge-dependency-prs.sh --view <evidence.json>
#        Run inside the repo checkout: the strings the model asks about are
#        searched in the working tree.
#        --view prints the trimmed evidence the model would get, for a worker
#        that judges by other means.
#
# Steps:
#   1. Trim each evidence file to what the judgement needs.
#   2. Ask the model once for all of them.
#   3. Search the repo for the strings the model asked about, and ask once
#      more for those PRs with the hits attached.
#   4. Check the answers and write one judgement file per PR.
#
# Exit 0 means <dir>/judgement-<pr>.json exists for every PR given, each with
# a level and a verdict. The render script still checks each against its
# evidence's floor.
set -euo pipefail

script_dir=${0:A:h}

# Print the part of one evidence file a judgement needs: fired rules only,
# no notes for a test-only package (its release-note rule is skipped), and no
# field that reports "nothing found".
print_judge_view() {
  jq '{
    floor, tier, ecosystem, judge,
    fired_rules: [.rules[] | select(.fired) | {id, level, evidence}],
    packages: [.packages[] | {
        name, from, to, bump, dev, direct, named, test_only, description,
        usage: (.usage | {status, file_count, runtime_file_count, files: (.files // [] | .[0:5]), symbols})
      }
      + (if .test_only then {} else {notes: (.notes | {source, text} + (if .cut or .truncated then {incomplete: true, omitted_lines} else {} end))} end)
      + (if .requirements.status != "unchanged" then {requirements} else {} end)
      + (if (.advisories.fixed // [] | length) > 0 then {advisories_fixed: [.advisories.fixed[] | {id, vulnerable_functions, used_in}]} else {} end)
      + (if (.published_resources.status | IN("unknown", "truncated")) or ((.published_resources.shadowed // []) | length) > 0
         then {published_resources} else {} end)]
  }
  + (if any(.packages[]; .requirements.status != "unchanged") then {repo_runtime} else {} end)
  + (if .ci.ecosystem_jobs == "unknown" then {ci_jobs: .ci.jobs} else {} end)' "$1"
}

if [[ ${1:-} == --view ]]; then
  print_judge_view "$2"
  exit
fi

model='' out_dir='' evidence_files=()
while (( $# > 0 )); do
  case $1 in
    --model) model=$2; shift ;;
    --out-dir) out_dir=$2; shift ;;
    *) evidence_files+=("$1") ;;
  esac
  shift
done
[[ -n $model && -n $out_dir && ${#evidence_files} -gt 0 ]] || { print -u2 'usage: judge-dependency-prs.sh --model <haiku|sonnet> --out-dir <dir> <evidence.json>...'; exit 2; }
mkdir -p "$out_dir"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

# 1. Trim each evidence file to what the judgement needs.
print '{}' >"$work_dir/request.json"
for evidence_file in $evidence_files; do
  pr=$(jq -r '.pr' "$evidence_file")
  jq --arg pr "$pr" --argjson view "$(print_judge_view "$evidence_file")" '. + {($pr): $view}' "$work_dir/request.json" >"$work_dir/request.next"
  mv "$work_dir/request.next" "$work_dir/request.json"
done

# Send one request file to the model and print its answer as JSON. No settings
# are loaded, so user memory, hooks and plugins add nothing to the prompt.
# The answer may come wrapped in a code fence or followed by a remark; keep
# what is between the outermost braces.
ask_model() {
  local request=$1 response=$work_dir/response-$2 attempt
  # A model now and then returns broken JSON; one more try settles it.
  for attempt in 1 2; do
    claude -p --model "$model" --system-prompt "$(<"$script_dir/../judge.md")" --tools "" \
      --output-format json --no-session-persistence --strict-mcp-config --setting-sources "" <"$request" >"$response-$attempt.json"
    jq -r '.result | .[index("{"):(rindex("}") + 1)]' "$response-$attempt.json" | jq '.' 2>/dev/null && return
  done
  cp "$response-2.json" "$out_dir/answer-raw.json"
  print -u2 "judge: the answer is not JSON; the raw response is in $out_dir/answer-raw.json"
  return 1
}

# Print the hits for each string as {string: ["path:line: text", …]}. The
# strings come from a model that read release notes, so they are only ever
# passed as literal search text.
search_repo() {
  local term results='{}'
  for term in "$@"; do
    results=$(jq --arg term "$term" --arg hits "$(rg -n -F -m 3 -g '!*.lock' -g '!pnpm-lock.yaml' -g '!package-lock.json' -- "$term" . 2>/dev/null | head -8 | cut -c1-240 || true)" \
      '. + {($term): ($hits | split("\n") | map(select(. != "")))}' <<<"$results")
  done
  print -r -- "$results"
}

# 2. Ask the model once for all of them.
ask_model "$work_dir/request.json" first >"$work_dir/answer.json"

# 3. Search the repo for the strings the model asked about, and ask once
#    more for those PRs with the hits attached.
print '{}' >"$work_dir/request-second.json"
for pr in "${(@f)$(jq -r 'to_entries[] | select((.value.searches // []) | length > 0) | .key' "$work_dir/answer.json")}"; do
  [[ -n $pr ]] || continue
  terms=("${(@f)$(jq -r --arg pr "$pr" '.[$pr].searches[0:8][] | strings | select(length >= 3)' "$work_dir/answer.json")}")
  jq --arg pr "$pr" --argjson results "$(search_repo "${terms[@]}")" --slurpfile request "$work_dir/request.json" \
    '. + {($pr): ($request[0][$pr] + {search_results: $results})}' "$work_dir/request-second.json" >"$work_dir/request.next"
  mv "$work_dir/request.next" "$work_dir/request-second.json"
done
if [[ $(jq 'length' "$work_dir/request-second.json") -gt 0 ]]; then
  ask_model "$work_dir/request-second.json" second >"$work_dir/answer-second.json"
  jq -s '.[0] + .[1]' "$work_dir/answer.json" "$work_dir/answer-second.json" >"$work_dir/answer.next"
  mv "$work_dir/answer.next" "$work_dir/answer.json"
fi

# 4. Check the answers and write one judgement file per PR.
print -u2 -- '--------- Result ---------'
for evidence_file in $evidence_files; do
  pr=$(jq -r '.pr' "$evidence_file")
  jq -e --arg pr "$pr" '.[$pr] | select((.level | IN("Low", "Medium", "High")) and (.verdict | length) > 0)' "$work_dir/answer.json" >"$out_dir/judgement-$pr.json" \
    || { print -u2 "judge: no usable judgement for PR $pr; the raw answer is in $out_dir/answer-raw.json"; cp "$work_dir/answer.json" "$out_dir/answer-raw.json"; exit 1; }
  jq -r --arg pr "$pr" '"\($pr)\t\(.level)\tunsure=\(if (.unsure // "") == "" then "-" else .unsure end)"' "$out_dir/judgement-$pr.json"
done
jq -rs '"tokens\t\(map(.usage | .input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens + .output_tokens) | add)\tseconds\t\(map(.duration_ms) | add / 1000 | floor)\tcalls\t\(length)"' "$work_dir"/response-*.json
