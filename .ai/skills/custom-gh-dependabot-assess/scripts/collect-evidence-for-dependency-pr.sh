#!/bin/zsh
# Collect the evidence a dependency-bump PR assessment needs and settle every
# risk rule that takes no judgement, so the model that writes the assessment
# reads one JSON file instead of fetching lockfiles, advisories and CI logs
# itself. The rule wording lives in ../SKILL.md; this script reports facts and
# the id of each rule they fire.
#
# Usage: collect-evidence-for-dependency-pr.sh <pr-number>
#        collect-evidence-for-dependency-pr.sh --self-check
#        Run inside the repo checkout: usage is searched in the working tree.
#
# Steps:
#   1. Read the PR once, so every check sees the same head commit.
#   2. Compare the base and head lockfiles.
#   3. List the packages to assess: the ones the PR names, plus every direct
#      dependency the lockfile moves.
#   4. Per package: advisories, release notes, usage, runtime floor, entry
#      points, published Laravel resources.
#   5. Read CI: one result per job, and for a failed job the base branch's
#      result and the failing lines of its log.
#   6. Apply the mechanical rules and print the evidence as JSON.
#
# Exit 0 means the JSON on stdout is complete. A lookup that failed is recorded
# as "unknown" in the JSON, never as an empty result, and fires a Medium rule.
# The `floor` it reports is the lowest level the assessment may give: PR text,
# release notes and CI logs can raise it but not lower it.
#
# shortcut: reads composer.lock, pnpm-lock.yaml and package-lock.json, and
# reports `"supported": false` for anything else (yarn.lock, GitHub Actions);
# add a reader in read_lockfile when a repo needs one.
set -euo pipefail

cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/dependabot-assess
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

# jq helpers shared by every filter below: version parsing and bump size.
# e.g. bump("v1.2.6"; "1.2.7") → "patch", bump("0.4.0"; "0.5.0") → "major",
#      bump("26.3.4(typescript@7.0.2)"; "26.3.4") → "none"
jq_defs='
def semver:
  (tostring | sub("^v"; "") | sub("\\(.*$"; "")) as $text
  | ($text | capture("^(?<core>[0-9]+(\\.[0-9]+)*)(?<pre>[-+].*)?$")? // null) as $parts
  | if $parts == null then null
    else {nums: (($parts.core | split(".") | map(tonumber)) + [0, 0, 0] | .[0:3]), pre: ($parts.pre // "")}
    end;
def bump($from; $to):
  ($from | semver) as $old | ($to | semver) as $new
  | if $old == null or $new == null or $old.pre != "" or $new.pre != "" then "unknown"
    elif $new.nums == $old.nums then "none"
    elif $new.nums < $old.nums then "downgrade"
    elif $new.nums[0] != $old.nums[0] then "major"
    elif $new.nums[1] != $old.nums[1] then (if $old.nums[0] == 0 then "major" else "minor" end)
    else "patch"
    end;
def bump_rank: {"none": 0, "patch": 1, "minor": 2, "major": 3, "unknown": 3, "downgrade": 3}[.];
def url_host: if . == null then null else (capture("^https?://(?<host>[^/]+)").host? // null) end;
'

# Fail loudly when the version classifier misreads one of the shapes real
# lockfiles carry; every tier and the downgrade rule depend on it.
self_check() {
  jq -en "$jq_defs"'
    [ bump("v1.2.6"; "1.2.7") == "patch",
      bump("13.34.0"; "13.40.0") == "minor",
      bump("1.7.0"; "2.2.1") == "major",
      bump("0.4.0"; "0.5.0") == "major",
      bump("0.4.1"; "0.4.2") == "patch",
      bump("2.0.0"; "1.9.0") == "downgrade",
      bump("26.3.4(typescript@7.0.2)"; "26.3.4") == "none",
      bump("1.0.0-beta.1"; "1.0.0") == "unknown",
      bump("link:../ui"; "1.0.0") == "unknown"
    ] | all' >/dev/null
  print 'self-check passed'
}

# Run gh and keep stdout only: gh prints hints on stderr that would corrupt
# JSON. The exit status tells the caller a lookup failed, so it can record
# "unknown" instead of an empty result.
gh_read() {
  # Counted in a file because most calls run in a subshell.
  print -n . >>"$work_dir/api_calls"
  gh "$@" 2>/dev/null
}

# Print one lockfile at a commit as {packages, direct} in a shape both
# ecosystems share, or fail when the file cannot be fetched.
# packages: every locked package; direct: the ones a manifest asks for.
read_lockfile() {
  local lockfile=$1 ref=$2 raw=$work_dir/raw.lock manifest=$work_dir/raw.manifest

  gh_read api "repos/{owner}/{repo}/contents/$lockfile?ref=$ref" -H 'Accept: application/vnd.github.raw' >"$raw" || return 1

  if [[ $lockfile == *composer.lock ]]; then
    gh_read api "repos/{owner}/{repo}/contents/${lockfile%.lock}.json?ref=$ref" -H 'Accept: application/vnd.github.raw' >"$manifest" || return 1
    jq "$jq_defs"'
      ($manifest[0].require // {} | keys) as $prod
      | ($manifest[0]["require-dev"] // {} | keys) as $dev
      | [(.packages[] | .dev = false), (.["packages-dev"][] | .dev = true)]
      | map({
          name,
          version: (.version | sub("^v"; "")),
          dev,
          host: (.dist.url | url_host),
          repo: ((.dist.url // "") | capture("repos/(?<repo>[^/]+/[^/]+)/zipball").repo? // null),
          ref: (.dist.reference // null),
          install_code: (.type == "composer-plugin"),
          description: (.description // null),
          requires: ((.require // {}) | with_entries(select(.key | test("^(php$|ext-)")))),
          namespaces: ((.autoload["psr-4"] // {}) | keys)
        })
      | {packages: ., direct: map(select(.name as $name | ($prod + $dev) | index($name)) | {name, version, dev})}
    ' --slurpfile manifest "$manifest" "$raw"
    return
  fi

  if [[ $lockfile == *package-lock.json ]]; then
    # Keys are install paths; the package name is what follows the last
    # "node_modules/". e.g. "node_modules/a/node_modules/@scope/b" → "@scope/b"
    jq "$jq_defs"'
      (.packages[""] // {}) as $root
      | [.packages | to_entries[] | select(.key != "" and (.value.link | not))
          | {
              name: (.key | sub("^.*node_modules/"; "")),
              version: .value.version,
              dev: (.value.dev == true),
              host: (.value.resolved | url_host),
              repo: null, ref: null,
              install_code: (.value.hasInstallScript == true),
              requires: (.value.engines // {} | if type == "object" then . else {} end),
              namespaces: [],
              top_level: (.key | test("^node_modules/[^/]+(/[^/]+)?$") and (test("/node_modules/.*node_modules/") | not))
            }] as $packages
      | def direct($names; $dev): $names[] as $name
          | ($packages | map(select(.name == $name and .top_level)) | first) as $entry
          | select($entry != null) | {name: $name, version: $entry.version, dev: $dev};
      {
        packages: ($packages | map(del(.top_level))),
        direct: [direct(($root.dependencies // {}) | keys; false), direct(($root.devDependencies // {}) | keys; true)]
      }' "$raw"
    return
  fi

  yq -o=json '.' "$raw" | jq "$jq_defs"'
    def plain: tostring | sub("\\(.*$"; "");
    {
      packages: ((.packages // {}) | to_entries | map(
        (.key | capture("^(?<name>@?[^@]+)@(?<version>.+)$")) as $key
        | {
            name: $key.name,
            version: ($key.version | plain),
            dev: false,
            host: (.value.resolution.tarball // null | url_host),
            repo: null,
            ref: null,
            install_code: (.value.requiresBuild == true or .value.hasInstallScript == true),
            requires: (.value.engines // {}),
            namespaces: []
          })),
      direct: [(.importers // {})[] | (
        ((.dependencies // {}) | to_entries[] | {name: .key, version: (.value.version | plain), dev: false}),
        ((.devDependencies // {}) | to_entries[] | {name: .key, version: (.value.version | plain), dev: true})
      )] | unique_by(.name)
    }'
}

# Print what the head lockfile changed against the base one.
# shortcut: `duplicates_new` only watches packages an app must hold one copy
# of; extend the list when a repo shares another singleton.
diff_lockfiles() {
  jq -n "$jq_defs"'
    def versions_by_name: group_by(.name) | map({key: .[0].name, value: (map(.version) | unique)}) | from_entries;
    ($base[0].packages | versions_by_name) as $old
    | ($head[0].packages | versions_by_name) as $new
    | ($base[0].direct | map({key: .name, value: .version}) | from_entries) as $old_direct
    | {
        direct_moves: [$head[0].direct[] | select($old_direct[.name] != .version)
          | {name, from: ($old_direct[.name] // null), to: .version, dev}],
        moved_total: ([$new | to_entries[] | select($old[.key] != .value)] | length),
        added: [$new | keys[] | select($old[.] == null)],
        host_changes: [$head[0].packages[] | select(.host != null) | . as $package
          | ([$base[0].packages[] | select(.name == $package.name and .host != null) | .host] | unique) as $hosts
          | select(($hosts | length) > 0 and ($hosts | index($package.host) | not))
          | {name, from: $hosts, to: .host}] | unique,
        install_code_new: [$head[0].packages[] | select(.install_code) | .name as $name
          | select([$base[0].packages[] | select(.name == $name and .install_code)] | length == 0) | $name] | unique,
        duplicates_new: [$new | to_entries[]
          | select(.key | test("^(react|react-dom|react-router|react-router-dom|react-redux|redux|zustand|@tanstack/react-query|i18next|react-i18next|vue|pinia)$"))
          | select((.value | length) > 1 and (($old[.key] // []) | length) <= 1) | .key]
      }
  ' --slurpfile base "$1" --slurpfile head "$2"
}

# Print the advisories that affect one package version, one JSON object per
# line, including malware records, which the default lookup leaves out.
list_advisories() {
  local ecosystem=$1 package=$2 version=$3 type

  for type in reviewed malware; do
    gh_read api --paginate "/advisories?ecosystem=$ecosystem&type=$type&affects=$package@$version" \
      --jq '.[] | {id: .ghsa_id, severity, type, url: .html_url, vulnerable_functions: [.vulnerabilities[]?.vulnerable_functions[]?]}' || return 1
  done
}

# Print the upstream release notes for the versions after $from up to $to, and
# keep them in the cache: a version range reads the same for every PR and repo.
# Fails when the repo publishes no release in the range, or when the range
# starts further back than the 1000 newest releases.
fetch_release_notes() {
  local package=$1 repo=$2 from=$3 to=$4
  local cached=$cache_dir/notes/$package/$from..$to.md

  if [[ -s $cached ]]; then
    cat "$cached"
    return
  fi

  # Page back until a page holds a release at or below $from, so a long range
  # is never read from its newest releases only.
  local releases=$work_dir/releases.jsonl page reached_start=false
  : >"$releases"
  for page in {1..10}; do
    gh_read api "repos/$repo/releases?per_page=100&page=$page" --jq '.[] | {tag_name, body}' >"$work_dir/page.jsonl" || return 1
    [[ -s $work_dir/page.jsonl ]] || { reached_start=true; break; }
    cat "$work_dir/page.jsonl" >>"$releases"
    if jq -es "$jq_defs"'($from | semver) as $old | any(.[]; (.tag_name | semver) as $tag | $tag != null and $tag.nums <= $old.nums)' --arg from "$from" "$work_dir/page.jsonl" >/dev/null; then
      reached_start=true
      break
    fi
  done
  [[ $reached_start == true ]] || return 1

  local notes
  notes=$(jq -rs "$jq_defs"'
    ($from | semver) as $old | ($to | semver) as $new
    | [.[] | (.tag_name | semver) as $tag
        | select($tag != null and $tag.pre == "" and $tag.nums > $old.nums and $tag.nums <= $new.nums)]
    | sort_by(.tag_name | semver | .nums)
    | map("## \(.tag_name)\n\(.body // "")") | join("\n\n")
  ' --arg from "$from" --arg to "$to" "$releases") || return 1
  [[ -n $notes ]] || return 1

  # Drop the author and link tail of each changelog line; it doubles the size.
  # e.g. "* Fix clone() on relations by @someone in https://github.com/…/pull/1"
  notes=$(sed -E 's/ by @[^ ]+ in https:[^ ]+$//; /^\*\*Full Changelog\*\*/d' <<<"$notes")

  mkdir -p "${cached:h}"
  print -r -- "$notes" >"$cached"
  print -r -- "$notes"
}

# Print where the working tree uses a package: how many files, the first ten,
# and the symbols or import specifiers it takes, so release notes can be
# matched against them without another search.
find_usage() {
  local ecosystem=$1 package=$2 namespace=$3 files symbols

  if [[ $ecosystem == composer ]]; then
    [[ -n $namespace ]] || { print '{"status": "unknown"}'; return; }
    local pattern="${namespace//\\/\\\\}[A-Za-z0-9_\\\\]+"
    files=$(rg -l -F "$namespace" -g '*.php' . 2>/dev/null || true)
    symbols=$(rg -o --no-filename -g '*.php' "$pattern" . 2>/dev/null | sort | uniq -c | sort -rn | head -40 | awk '{print $2}' || true)
  else
    local pattern="from ['\"]${package}(/[^'\"]*)?['\"]|require\\(['\"]${package}(/[^'\"]*)?['\"]\\)"
    files=$(rg -l -g '*.{ts,tsx,js,jsx,mjs,cjs,vue}' "$pattern" . 2>/dev/null || true)
    symbols=$(rg -o --no-filename -g '*.{ts,tsx,js,jsx,mjs,cjs,vue}' "import [^;'\"]*from ['\"]${package}(/[^'\"]*)?['\"]" . 2>/dev/null | sort -u | head -40 || true)
  fi

  jq -n --arg files "$files" --arg symbols "$symbols" '{
    status: "ok",
    file_count: ($files | split("\n") | map(select(. != "")) | length),
    files: ($files | split("\n") | map(select(. != "")) | .[0:10]),
    symbols: ($symbols | split("\n") | map(select(. != "")))
  }'
}

# Print the config, view and migration files an upstream range changed that
# the working tree holds a published copy of.
find_published_resources() {
  local repo=$1 old_ref=$2 new_ref=$3 changed

  changed=$(gh_read api "repos/$repo/compare/$old_ref...$new_ref" --jq '[.files[].filename]') || { print '{"status": "unknown"}'; return; }

  local published=()
  local file
  for file in $(jq -r '.[] | select(test("^(config/|resources/views/|database/migrations/)"))' <<<"$changed"); do
    [[ $file == config/* && -f config/${file:t} ]] && published+=("$file")
    [[ $file == resources/views/* && -d resources/views/vendor ]] && published+=("$file")
    [[ $file == database/migrations/* && -n $(print -l database/migrations/*${${file:t}#*_*_*_*_}(N)) ]] && published+=("$file")
  done

  # GitHub's compare lists at most 300 files, so a longer range is incomplete.
  jq -n --argjson changed "$changed" --args '{
    status: (if ($changed | length) >= 300 then "truncated" else "ok" end),
    shadowed: $ARGS.positional
  }' "${published[@]}"
}

# Print the runtime a package version asks for from the npm registry, without
# the peers it marks optional: an unmet optional peer is not a conflict.
npm_requirements() {
  npm view "$1@$2" engines peerDependencies peerDependenciesMeta exports type main --json 2>/dev/null | jq '
    (.peerDependenciesMeta // {}) as $meta
    | if .peerDependencies then .peerDependencies |= with_entries(select($meta[.key].optional != true)) else . end
    | del(.peerDependenciesMeta) | del(.peerDependencies | select(. == {}))'
}

# Print one package's evidence as a JSON object.
collect_package() {
  local package_json=$1
  local name from to bump named repo old_ref new_ref namespace
  name=$(jq -r '.name' <<<"$package_json")
  from=$(jq -r '.from // ""' <<<"$package_json")
  to=$(jq -r '.to' <<<"$package_json")
  bump=$(jq -r '.bump' <<<"$package_json")
  named=$(jq -r '.named' <<<"$package_json")
  repo=$(jq -r '.repo // ""' <<<"$package_json")
  old_ref=$(jq -r '.old_ref // ""' <<<"$package_json")
  new_ref=$(jq -r '.new_ref // ""' <<<"$package_json")
  namespace=$(jq -r '.namespace // ""' <<<"$package_json")

  # A pnpm lockfile does not say where a package's source lives; npm does.
  # e.g. "git+https://github.com/i18next/i18next.git" → "i18next/i18next"
  if [[ -z $repo && $ecosystem == npm ]]; then
    repo=$(npm view "$name@$to" repository.url 2>/dev/null | sed -nE 's#.*github\.com[/:]([^/]+/[^/.]+)(\.git)?$#\1#p' || true)
  fi

  local description
  description=$(jq -r '.description // ""' <<<"$package_json")
  [[ -z $description && $ecosystem == npm ]] && description=$(npm view "$name@$to" description 2>/dev/null || true)

  # Advisories: what the old and the new version each carry.
  local advisories='{"status": "unknown"}' old_advisories new_advisories
  if [[ -n $from ]] && old_advisories=$(list_advisories "$ecosystem" "$name" "$from") && new_advisories=$(list_advisories "$ecosystem" "$name" "$to"); then
    advisories=$(jq -n --arg old "$old_advisories" --arg new "$new_advisories" '
      ([$old | split("\n")[] | select(. != "") | fromjson]) as $before
      | ([$new | split("\n")[] | select(. != "") | fromjson]) as $after
      | ($before | map(.id)) as $before_ids | ($after | map(.id)) as $after_ids
      | {
          status: "ok",
          introduced: [$after[] | select(.id as $id | $before_ids | index($id) | not)],
          fixed: [$before[] | select(.id as $id | $after_ids | index($id) | not)],
          still_open: [$after[] | select(.id as $id | $before_ids | index($id))]
        }')
  fi

  # Release notes: upstream releases for the range, else Dependabot's PR body
  # for a package the PR names.
  local notes='' notes_source=missing
  if [[ -n $repo && -n $from ]] && notes=$(fetch_release_notes "$name" "$repo" "$from" "$to"); then
    notes_source=releases
  elif [[ $named == true ]] && grep -qiE 'release notes|changelog' <<<"$pr_body"; then
    notes=$(sed -E 's/<[^>]+>//g' <<<"$pr_body" | grep -v '^[[:space:]]*$' || true)
    notes_source=pr-body
  fi
  # Dependabot marks a PR body it cut short; that is a gap in the notes.
  local notes_truncated=false
  [[ $notes_source == pr-body ]] && grep -q '(truncated)' <<<"$notes" && notes_truncated=true
  # 40000 characters is about 10k tokens; a longer range is cut to fit.
  local notes_cut=false
  if (( ${#notes} > 40000 )); then
    notes_cut=true
    notes=${notes[1,40000]}
  fi

  local usage
  usage=$(find_usage "$ecosystem" "$name" "$namespace")

  # Runtime floor and entry points: only what changed between the versions.
  local requirements='{"status": "unchanged"}'
  if [[ $ecosystem == composer ]]; then
    requirements=$(jq '{status: (if .old_requires == .new_requires then "unchanged" else "changed" end), old: .old_requires, new: .new_requires}' <<<"$package_json")
  elif [[ $bump != patch && -n $from ]]; then
    local old_npm new_npm
    if old_npm=$(npm_requirements "$name" "$from") && new_npm=$(npm_requirements "$name" "$to"); then
      requirements=$(jq -n --argjson old "${old_npm:-null}" --argjson new "${new_npm:-null}" '
        {status: (if $old == $new then "unchanged" else "changed" end)}
        + (if $old == $new then {} else {old: $old, new: $new} end)')
    else
      requirements='{"status": "unknown"}'
    fi
  fi

  local published='{"status": "not-applicable"}'
  if [[ $ecosystem == composer && $bump != patch && -n $repo && -n $old_ref && -n $new_ref ]]; then
    published=$(find_published_resources "$repo" "$old_ref" "$new_ref")
  fi

  jq -n --argjson package "$package_json" --argjson advisories "$advisories" --argjson usage "$usage" \
    --argjson requirements "$requirements" --argjson published "$published" \
    --arg notes "$notes" --arg notes_source "$notes_source" --argjson notes_truncated "$notes_truncated" --argjson notes_cut "$notes_cut" --arg repo "$repo" --arg description "$description" '
    ($package | del(.old_requires, .new_requires, .namespace, .old_ref, .new_ref)) + {
      repo: (if $repo == "" then null else $repo end),
      description: (if $description == "" then null else $description end),
      advisories: $advisories,
      usage: $usage,
      requirements: $requirements,
      published_resources: $published,
      notes: {source: $notes_source, truncated: $notes_truncated, cut: $notes_cut, text: $notes}
    }'
}

# Print CI as one result per job. Several runs of one job on the same commit
# count as passed when any of them passed, so a run cancelled by its own
# duplicate is not a failure.
summarise_ci() {
  jq '
    def result:
      if any(.[]; .conclusion == "SUCCESS" or .state == "SUCCESS") then "passed"
      elif any(.[]; (.status // "COMPLETED") != "COMPLETED" or .state == "PENDING" or .state == "EXPECTED") then "pending"
      elif any(.[]; (.conclusion // .state) | IN("FAILURE", "TIMED_OUT", "ERROR", "STARTUP_FAILURE", "ACTION_REQUIRED")) then "failed"
      elif any(.[]; .conclusion == "CANCELLED") then "cancelled"
      else "skipped"
      end;
    [.statusCheckRollup | group_by([.workflowName // "", .name // .context])[]
      | {job: (.[0].name // .[0].context), workflow: (.[0].workflowName // null), result: result,
         job_id: ([.[] | select((.conclusion // "") == "FAILURE") | .detailsUrl // "" | capture("/job/(?<id>[0-9]+)").id?] | first // null)}]
  ' <<<"$pr_json"
}

# Print one failed job's evidence: whether the same job passes on the base
# branch, the failing lines of its log, and a fingerprint of them so PRs that
# fail the same way can share one investigation.
collect_failed_job() {
  local job=$1 job_id=$2 base_result=unknown log='' failing='' errors=''

  if [[ -n $base_checks ]]; then
    base_result=$(jq -r --arg job "$job" '
      [.[] | select(.name == $job) | .conclusion] as $conclusions
      | if ($conclusions | length) == 0 then "not-run"
        elif any($conclusions[]; . == "success") then "passed"
        else ($conclusions | first // "unknown")
        end' <<<"$base_checks")
  fi

  if [[ -n $job_id ]] && log=$(gh_read run view --job "$job_id" --log-failed); then
    log=$(cut -f3- <<<"$log" | sed -E $'s/(\x1b|\\^\\[)\\[[0-9;]*[A-Za-z]//g; s/^[0-9T:.-]+Z //')
    failing=$(grep -E '^[[:space:]]*(FAILED|FAIL|✗|×)[[:space:]]' <<<"$log" | sed -E 's/[[:space:]]+/ /g' | sort -u | head -30 || true)
    # The message of a failure sits on the lines under its header, so keep the
    # five lines that follow each of the first three failing tests.
    errors=$(awk '/^[[:space:]]*(FAILED|FAIL|✗|×)[[:space:]]/ && shown < 3 { shown++; left = 5; next } left > 0 && NF { left--; print }' <<<"$log" | sed -E 's/[[:space:]]+/ /g' | awk '!seen[$0]++' | cut -c1-400 || true)
  fi

  local fingerprint=''
  [[ -n $failing$errors ]] && fingerprint=$(print -r -- "$failing$errors" | sed -E 's/[0-9]+(\.[0-9]+)?s//g' | shasum | cut -c1-12)

  jq -n --arg job "$job" --arg base "$base_result" --arg failing "$failing" --arg errors "$errors" --arg fingerprint "$fingerprint" '{
    job: $job,
    base_branch_result: $base,
    fingerprint: (if $fingerprint == "" then null else $fingerprint end),
    failing_tests: ($failing | split("\n") | map(select(. != ""))),
    errors: ($errors | split("\n") | map(select(. != "")))
  }'
}

if [[ ${1:-} == --self-check ]]; then
  self_check
  exit
fi

pr=$1

# 1. Read the PR once, so every check sees the same head commit.
pr_json=$(gh_read pr view "$pr" --json number,title,body,url,author,baseRefName,baseRefOid,headRefOid,files,changedFiles,commits,statusCheckRollup)
head_sha=$(jq -r '.headRefOid' <<<"$pr_json")
base_sha=$(jq -r '.baseRefOid' <<<"$pr_json")
base_branch=$(jq -r '.baseRefName' <<<"$pr_json")
pr_body=$(jq -r '.body' <<<"$pr_json")

lockfile=$(jq -r '[.files[].path | select(test("(^|/)(composer\\.lock|pnpm-lock\\.yaml|package-lock\\.json)$"))] | first // ""' <<<"$pr_json")
ecosystem=npm
[[ $lockfile == *composer.lock ]] && ecosystem=composer

non_package_files=$(jq -c '[.files[].path | select(test("(^|/)(composer\\.json|composer\\.lock|package\\.json|package-lock\\.json|yarn\\.lock|pnpm-lock\\.yaml)$") | not)]' <<<"$pr_json")
file_list_complete=$(jq '.changedFiles == (.files | length)' <<<"$pr_json")

if [[ -z $lockfile ]]; then
  jq -n --argjson pr "$pr" --arg head "$head_sha" --argjson files "$non_package_files" \
    '{pr: $pr, head_sha: $head, supported: false, reason: "no composer.lock, pnpm-lock.yaml or package-lock.json in the diff", non_package_files: $files}'
  exit
fi

# 2. Compare the base and head lockfiles.
read_lockfile "$lockfile" "$base_sha" >"$work_dir/base.json"
read_lockfile "$lockfile" "$head_sha" >"$work_dir/head.json"
lock_diff=$(diff_lockfiles "$work_dir/base.json" "$work_dir/head.json")

# 3. List the packages to assess: the ones the PR names, plus every direct
#    dependency the lockfile moves.
# e.g. trailer line "- dependency-name: laravel/pail"
named_packages=$(jq -r '.commits[].messageBody' <<<"$pr_json" | sed -n 's/^- dependency-name: //p' | sort -u)
package_list=$(jq -n "$jq_defs"'
  ($named | split("\n") | map(select(. != ""))) as $names
  | ($diff.direct_moves | map(.name)) as $moved
  | def entry($name; $side): [$side.packages[] | select(.name == $name)];
  [($names + $moved | unique)[] as $name
    | ($diff.direct_moves | map(select(.name == $name)) | first) as $move
    | entry($name; $base[0]) as $old | entry($name; $head[0]) as $new
    | ($move.to // ([$new[].version] - [$old[].version] | first) // ($new | first | .version)) as $to
    | ($move.from // ([$old[].version] - [$new[].version] | first)) as $from
    | select($to != null and $from != $to)
    | ($new | map(select(.version == $to)) | first) as $new_entry
    | ($old | map(select(.version == $from)) | first) as $old_entry
    | {
        name: $name, from: $from, to: $to,
        bump: (if $from == null then "unknown" else bump($from; $to) end),
        # A PR with no Dependabot trailer names every direct package it moves.
        named: (($names | length) == 0 or ($names | index($name) != null)),
        direct: ($move != null),
        dev: ($move.dev // $new_entry.dev // false),
        repo: $new_entry.repo, old_ref: $old_entry.ref, new_ref: $new_entry.ref,
        namespace: ($new_entry.namespaces | sort_by(length) | first // null),
        description: ($new_entry.description // null),
        old_requires: ($old_entry.requires // {}), new_requires: ($new_entry.requires // {})
      }]
' --arg named "$named_packages" --argjson diff "$lock_diff" --slurpfile base "$work_dir/base.json" --slurpfile head "$work_dir/head.json")

# 4. Per package: advisories, release notes, usage, runtime floor, entry
#    points, published Laravel resources.
packages='[]'
for package_json in "${(@f)$(jq -c '.[]' <<<"$package_list")}"; do
  [[ -n $package_json ]] || continue
  packages=$(jq --argjson package "$(collect_package "$package_json")" '. + [$package]' <<<"$packages")
done

# 5. Read CI: one result per job, and for a failed job the base branch's
#    result and the failing lines of its log.
ci_jobs=$(summarise_ci)
failed_jobs='[]'
if jq -e 'any(.[]; .result == "failed")' <<<"$ci_jobs" >/dev/null; then
  base_checks=$(gh_read api --paginate "repos/{owner}/{repo}/commits/$base_branch/check-runs?per_page=100" --jq '.check_runs[] | {name, conclusion}' | jq -s '.') || base_checks=''
  for failed_job in "${(@f)$(jq -c '.[] | select(.result == "failed")' <<<"$ci_jobs")}"; do
    failed_jobs=$(jq --argjson job "$(collect_failed_job "$(jq -r '.job' <<<"$failed_job")" "$(jq -r '.job_id // ""' <<<"$failed_job")")" '. + [$job]' <<<"$failed_jobs")
  done
fi

# 6. Apply the mechanical rules and print the evidence as JSON.
# shortcut: the jobs for an ecosystem are recognised by name; a repo whose job
# names match neither pattern reports `ecosystem_jobs: "unknown"`.
print -u2 -- '--------- Result ---------'
jq -n "$jq_defs"'
  def level_rank: {"Low": 0, "Medium": 1, "High": 2}[.];
  (if $ecosystem == "composer" then "backend|php|pest|phpunit|laravel|composer" else "frontend|front-end|node|vite|vitest|jest|build|pnpm|npm" end) as $job_pattern
  | ($ci | map(select(.job | test($job_pattern; "i")))) as $ecosystem_jobs
  | ($packages | map(.bump | bump_rank) | max // 3) as $largest
  | {
      pr: $pr, head_sha: $head, base_branch: $base_branch, ecosystem: $ecosystem, lockfile: $lockfile, supported: true,
      tier: (["patch", "patch", "minor", "major"][$largest]),
      packages: $packages,
      lockfile_changes: ($diff | del(.direct_moves) + {unnamed_direct_moves: [$packages[] | select(.direct and (.named | not)) | "\(.name) \(.from) → \(.to)"]}),
      non_package_files: $non_package_files,
      ci: {
        passed: ($ci | map(select(.result == "passed")) | length),
        pending: [$ci[] | select(.result == "pending") | .job],
        cancelled: [$ci[] | select(.result == "cancelled") | .job],
        skipped: ($ci | map(select(.result == "skipped")) | length),
        failed: $failed,
        ecosystem_jobs: (if ($ecosystem_jobs | length) == 0 then "unknown"
          elif any($ecosystem_jobs[]; .result == "passed" or .result == "failed") then "ran"
          else "skipped" end)
      },
      api_calls: $api_calls
    }
  | . as $evidence
  | ($failed | map("`\(.job)`") | join(", ")) as $failed_jobs
  | .rules = [
      {id: "advisory-introduced", level: "High", fired: any($packages[]; (.advisories.introduced // []) | length > 0),
       evidence: ([$packages[] | .name as $name | (.advisories.introduced // [])[] | "\(.id) in \($name)"] | join(", "))},
      {id: "ci-red-bump-caused", level: "High", fired: any($failed[]; .base_branch_result == "passed"),
       evidence: (if ($failed | length) > 0 then "\($failed_jobs) fails here, passes on `\($base_branch)`" else "" end)},
      {id: "advisory-lookup-failed", level: "Medium", fired: any($packages[]; .advisories.status != "ok"),
       evidence: ([$packages[] | select(.advisories.status != "ok") | .name] | join(", "))},
      {id: "ci-red-unresolved", level: "Medium", fired: any($failed[]; .base_branch_result != "passed"),
       evidence: ([$failed[] | select(.base_branch_result != "passed") | "`\(.job)` on base: \(.base_branch_result)"] | join(", "))},
      {id: "ci-incomplete", level: "Medium", fired: (($ci | length) == 0 or (.ci.pending + .ci.cancelled | length) > 0),
       evidence: ((.ci.pending + .ci.cancelled) | map("`\(.)`") | join(", "))},
      {id: "ci-ecosystem-jobs-skipped", level: "Medium", fired: (.ci.ecosystem_jobs == "skipped"), evidence: ""},
      {id: "diff-outside-package-files", level: "Medium", fired: (($non_package_files | length) > 0 or ($file_list_complete | not)),
       evidence: ($non_package_files | .[0:5] | map("`\(.)`") | join(", "))},
      {id: "lockfile-host-change", level: "Medium", fired: ($diff.host_changes | length > 0),
       evidence: ($diff.host_changes | map("\(.name) → \(.to)") | join(", "))},
      {id: "lockfile-install-code", level: "Medium", fired: ($diff.install_code_new | length > 0), evidence: ($diff.install_code_new | join(", "))},
      {id: "lockfile-duplicate-copy", level: "Medium", fired: ($diff.duplicates_new | length > 0), evidence: ($diff.duplicates_new | join(", "))},
      {id: "downgrade", level: "Medium", fired: any($packages[]; .bump == "downgrade"),
       evidence: ([$packages[] | select(.bump == "downgrade") | "\(.name) \(.from) → \(.to)"] | join(", "))},
      {id: "notes-missing", level: "Medium", fired: any($packages[]; (.dev | not) and (.bump | bump_rank) >= 2 and .notes.source == "missing"),
       evidence: ([$packages[] | select(.notes.source == "missing") | .name] | join(", "))},
      {id: "published-resource-changed", level: "Medium", fired: any($packages[]; (.published_resources.shadowed // []) | length > 0),
       evidence: ([$packages[] | (.published_resources.shadowed // [])[] | "`\(.)`"] | unique | join(", "))}
    ]
  | .floor = ([.rules[] | select(.fired) | .level] | max_by(level_rank) // "Low")
  # What still takes judgement; an empty list with a High floor needs none.
  | .judge = (if .floor == "High" then [] else [
      "notes-vs-usage",
      (if any($packages[]; .notes.cut or .notes.truncated) then "notes-incomplete-read-the-rest-upstream" else empty end),
      (if any($packages[]; .requirements.status != "unchanged") then "runtime-floor-and-entry-points" else empty end),
      (if any($packages[]; .published_resources.status | IN("unknown", "truncated")) then "published-resources" else empty end),
      (if ($non_package_files | length) > 0 then "formatter-output" else empty end)
    ] end)
  | .ci_wait = ((.ci.pending | length) > 0)
' --argjson pr "$pr" --arg head "$head_sha" --arg base_branch "$base_branch" --arg ecosystem "$ecosystem" --arg lockfile "$lockfile" \
  --argjson packages "$packages" --argjson diff "$lock_diff" --argjson ci "$ci_jobs" --argjson failed "$failed_jobs" \
  --argjson non_package_files "$non_package_files" --argjson file_list_complete "$file_list_complete" --argjson api_calls "$(wc -c <"$work_dir/api_calls" | tr -d " ")"
