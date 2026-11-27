#!/bin/zsh
# Collect the evidence a dependency-bump PR assessment needs and settle every
# risk rule that takes no judgement, so the model that judges the PR reads one
# JSON file instead of fetching lockfiles, advisories and CI logs itself. The
# rule wording lives in ../SKILL.md; this script reports facts and the id of
# each rule they fire.
#
# Usage: collect-evidence-for-dependency-pr.sh <pr-number>
#        collect-evidence-for-dependency-pr.sh --out-dir <dir> <pr-number>...
#        collect-evidence-for-dependency-pr.sh --self-check
#        Run inside the repo checkout: usage is searched in the working tree.
#        --out-dir collects several PRs at once into <dir>/ev-<pr>.json and
#        prints one summary line per PR.
#
# Steps:
#   1. Read the PR once, so every check sees the same head commit. Stop here
#      when CI is still running: the assessment waits for it anyway.
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
# reports `"supported": false` for anything else (yarn.lock, GitHub Actions, a
# PR that changes two lockfiles); add a reader in parse_lockfile when a repo
# needs one.
set -euo pipefail

cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/dependabot-assess
script_path=${0:A}

# jq helpers shared by every filter below: version parsing, bump size, and the
# two package lists the rules need.
# e.g. bump("v1.2.6"; "1.2.7") → "patch", bump("0.4.0"; "0.5.0") → "major",
#      bump("26.3.4(typescript@7.0.2)"; "26.3.4") → "none"
jq_defs='
def semver:
  (tostring | sub("^v"; "") | sub("\\(.*$"; "")) as $text
  | ($text | capture("^(?<core>[0-9]+(\\.[0-9]+)*)(?<pre>[-+].*)?$")? // null) as $parts
  | if $parts == null then null
    else {nums: (($parts.core | split(".") | map(tonumber)) + [0, 0, 0] | .[0:3]), pre: ($parts.pre // "")}
    end;
# The version a release tag stands for, or null when the tag belongs to
# another package of a monorepo.
# e.g. "v1.2.3" → 1.2.3; "@scope/pkg@1.2.3", "pkg@1.2.3", "pkg-v1.2.3" → 1.2.3
#      for that package; "other-pkg@1.2.3" → null
def tag_version($package):
  . as $tag
  | ($package | sub("^.*/"; "")) as $short
  | ([$package + "@", $short + "@", $short + "-v", $short + "/v", $short + "-", $short + "/"]
      | map(select(. as $prefix | $tag | startswith($prefix))) | first) as $prefix
  | (if $prefix then $tag[($prefix | length):] else $tag end) | semver;
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
# Packages that run only in lint, tests or local development tooling and
# cannot change what ships. A bundler, compiler or CSS framework is never on
# this list: it shapes the build.
def test_only: test("^("
  + "phpunit/phpunit|pestphp/.+|spatie/pest-plugin-.+|mockery/mockery|fakerphp/faker|nunomaduro/collision"
  + "|laravel/pint|phpstan/.+|larastan/larastan|rector/rector|driftingly/rector-laravel|deptrac/deptrac"
  + "|barryvdh/laravel-ide-helper|beyondcode/laravel-query-detector|itsgoingd/clockwork|spatie/laravel-ignition"
  + "|laravel/(pail|sail|boost|pao|breeze)"
  + "|eslint|@eslint/.+|(@[^/]+/)?eslint-(plugin|config)(-.+)?|@typescript-eslint/.+|typescript-eslint"
  + "|prettier|prettier-plugin-.+|oxfmt|oxlint|oxlint-.+|@biomejs/biome|stylelint|stylelint-.+|husky|lint-staged|@x18n/cli"
  + "|vitest|@vitest/.+|jest|@jest/.+|@testing-library/.+|@playwright/test|playwright|msw|jsdom|happy-dom|@faker-js/faker"
  + "|storybook|@storybook/.+|@chromatic-com/storybook|@types/.+"
  + ")$");
# Packages whose bump may rewrite source files without changing behaviour.
# A failed job whose only error lines are a network fault says nothing about
# the bump: the job has to be run again. A named failing test never counts.
def network_only:
  (.errors | map(select(test("Process completed with exit code") | not))) as $errors
  | (.failing_tests | length) == 0 and ($errors | length) > 0
    and all($errors[]; test("getaddrinfo|EAI_AGAIN|ENOTFOUND|ECONNRESET|ECONNREFUSED|ETIMEDOUT|socket hang up|Could not resolve host|Connection timed out|50[234] (Bad Gateway|Service Unavailable|Gateway Time-?out)"));
def formatter: test("^(oxfmt|oxlint|oxlint-.+|prettier|prettier-plugin-.+|eslint|@eslint/.+|eslint-(plugin|config)-.+|@biomejs/biome|stylelint|laravel/pint|friendsofphp/php-cs-fixer)$");
'

# Fail loudly when a helper misreads one of the shapes real lockfiles, release
# tags and Dependabot commits carry; the tiers and several rules depend on them.
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
      bump("link:../ui"; "1.0.0") == "unknown",
      ("v5.4.0" | tag_version("vite") | .nums) == [5, 4, 0],
      ("@tanstack/react-query@5.50.0" | tag_version("@tanstack/react-query") | .nums) == [5, 50, 0],
      ("react-query-v5.50.0" | tag_version("@tanstack/react-query") | .nums) == [5, 50, 0],
      ("create-vite@5.4.0" | tag_version("vite")) == null,
      ("vite-plugin-x@1.0.0" | tag_version("vite")) == null,
      ("happy-dom" | test_only), ("@types/node" | test_only),
      ("oxfmt" | test_only), ("@x18n/cli" | test_only), ("dotenv" | test_only | not), ("@tanstack/eslint-plugin-query" | test_only), ("laravel/pail" | test_only),
      ("vite" | test_only | not), ("typescript" | test_only | not), ("tailwindcss" | test_only | not),
      ({failing_tests: [], errors: ["Error: getaddrinfo EAI_AGAIN url", "##[error]Process completed with exit code 1."]} | network_only),
      ({failing_tests: [" FAIL a.spec.tsx"], errors: ["Error: getaddrinfo EAI_AGAIN url"]} | network_only | not),
      ({failing_tests: [], errors: ["Error: getaddrinfo EAI_AGAIN url", "error TS2304: Cannot find name"]} | network_only | not),
      ({failing_tests: [], errors: ["##[error]Process completed with exit code 1."]} | network_only | not)
    ] | all' >/dev/null

  [[ $(print -l -- '- dependency-name: "@types/node"' '- dependency-name: laravel/pail' | named_from_trailer | tr '\n' ' ') == '@types/node laravel/pail ' ]]
  [[ $(print 'git+https://github.com/vercel/next.js.git' | github_repo_from_url) == vercel/next.js ]]
  [[ $(print 'https://github.com/facebook/react/tree/main/packages/react' | github_repo_from_url) == facebook/react ]]
  [[ $(print 'git+ssh://git@github.com/i18next/i18next.git' | github_repo_from_url) == i18next/i18next ]]

  # A formatter rewrite is recognised; a changed literal, a changed string
  # and a statement moved to another file are not.
  print -l -- 'diff --git a/x.ts b/x.ts' "-import a from 'x';" '+import a from "x"' '-const  n = 1;' '+  const n = 1' >"$work_dir/format.diff"
  [[ $(is_formatter_rewrite "$work_dir/format.diff") == true ]]
  print -l -- 'diff --git a/x.ts b/x.ts' '-const n = 1' '+const n = 2' >"$work_dir/change.diff"
  [[ $(is_formatter_rewrite "$work_dir/change.diff") == false ]]
  print -l -- 'diff --git a/x.ts b/x.ts' '-const s = "a b"' '+const s = "ab"' >"$work_dir/literal.diff"
  [[ $(is_formatter_rewrite "$work_dir/literal.diff") == false ]]
  print -l -- 'diff --git a/x.ts b/x.ts' '-run()' 'diff --git a/y.ts b/y.ts' '+run()' >"$work_dir/moved.diff"
  [[ $(is_formatter_rewrite "$work_dir/moved.diff") == false ]]

  # Lockfile shapes: pnpm before v9 (leading "/" and root-level dependencies)
  # and a composer.lock without dev packages.
  print -l -- "lockfileVersion: '6.0'" 'dependencies:' "  '@babel/core':" '    specifier: ^7.24.0' '    version: 7.24.0' \
    'devDependencies:' '  vitest:' '    specifier: ^1.0.0' '    version: 1.6.0(@types/node@20.1.0)' \
    'packages:' '  /@babel/core@7.24.0:' '    resolution: {integrity: x}' '  /vitest@1.6.0(@types/node@20.1.0):' '    resolution: {integrity: y}' >"$work_dir/pnpm-lock.yaml"
  [[ $(parse_lockfile pnpm-lock.yaml "$work_dir/pnpm-lock.yaml" '' | jq -c '[.packages[].name], [.direct[] | "\(.name)@\(.version)"]' | tr -d '\n') == '["@babel/core","vitest"]["@babel/core@7.24.0","vitest@1.6.0"]' ]]
  print '{"packages":[{"name":"a/b","version":"v1.0.0","dist":{"url":"https://api.github.com/repos/a/b/zipball/abc"}}]}' >"$work_dir/composer.lock"
  print '{"require":{"a/b":"^1.0"}}' >"$work_dir/composer.json"
  [[ $(parse_lockfile composer.lock "$work_dir/composer.lock" "$work_dir/composer.json" | jq -c '.direct') == '[{"name":"a/b","version":"1.0.0","dev":false}]' ]]

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

# Print the package names of Dependabot's commit trailer; a scoped npm name is
# quoted there.
# e.g. '- dependency-name: "@types/node"' → @types/node
named_from_trailer() {
  sed -nE 's/^- dependency-name: ["'\'']?([^"'\'']+)["'\'']?[[:space:]]*$/\1/p' | sort -u
}

# Print "owner/repo" for a GitHub repository URL in any of the forms a
# registry carries, including repo names with a dot and monorepo subpaths.
github_repo_from_url() {
  sed -nE 's#.*github\.com[/:]([^/]+/[^/\#?]+).*#\1#p' | sed -E 's/\.git$//'
}

# Print one file as it is at a commit: from the local clone when it has the
# commit, which costs no API call, else from GitHub.
fetch_file() {
  local file=$1 ref=$2

  if git cat-file -e "$ref:$file" 2>/dev/null; then
    git show "$ref:$file"
    return
  fi
  gh_read api "repos/{owner}/{repo}/contents/$file?ref=$ref" -H 'Accept: application/vnd.github.raw'
}

# Print a raw lockfile as {packages, direct} in a shape both ecosystems share.
# packages: every locked package; direct: the ones a manifest asks for.
parse_lockfile() {
  local lockfile=$1 raw=$2 manifest=$3

  if [[ $lockfile == *composer.lock ]]; then
    jq "$jq_defs"'
      ($manifest[0].require // {} | keys) as $prod
      | ($manifest[0]["require-dev"] // {} | keys) as $dev
      | [((.packages // [])[] | .dev = false), ((.["packages-dev"] // [])[] | .dev = true)]
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

  # pnpm: package keys are "name@version" (with a leading "/" before v9), and
  # a lockfile without workspaces keeps its dependencies at the root.
  yq -o=json '.' "$raw" | jq "$jq_defs"'
    def plain: tostring | sub("\\(.*$"; "");
    def locked: if type == "object" then .version else . end | plain;
    {
      packages: ((.packages // {}) | to_entries | map(
        (.key | sub("^/"; "") | capture("^(?<name>@?[^@]+)@(?<version>.+)$")) as $key
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
      direct: [(.importers // {".": .})[] | (
        ((.dependencies // {}) | to_entries[] | {name: .key, version: (.value | locked), dev: false}),
        ((.devDependencies // {}) | to_entries[] | {name: .key, version: (.value | locked), dev: true})
      )] | unique_by([.name, .version])
    }'
}

# Print one lockfile at a commit as {packages, direct}, or fail when the file
# cannot be fetched. A commit never changes, so the parsed result is cached:
# every PR against the same base commit reads the base lockfile once.
read_lockfile() {
  local lockfile=$1 ref=$2
  local cached=$cache_dir/lockfiles/v2-$ref-${lockfile//\//_}.json

  if [[ ! -s $cached ]]; then
    local tmp
    tmp=$(mktemp -d "$work_dir/lockfile.XXXXXX")
    fetch_file "$lockfile" "$ref" >"$tmp/raw" || return 1
    if [[ $lockfile == *composer.lock ]]; then
      fetch_file "${lockfile%.lock}.json" "$ref" >"$tmp/manifest" || return 1
    fi
    parse_lockfile "$lockfile" "$tmp/raw" "$tmp/manifest" >"$tmp/parsed" || return 1
    mkdir -p "${cached:h}"
    mv "$tmp/parsed" "$cached"
  fi
  cat "$cached"
}

# Print the manifests whose change goes beyond dependency versions: a script,
# an autoload map or a plugin setting edited in a bump PR is a code change.
# A manifest that cannot be read is listed too, so the gap is never a pass.
list_manifest_edits() {
  local manifest
  for manifest in "${(@f)$(jq -r '.files[].path | select(test("(^|/)(composer|package)\\.json$"))' <<<"$pr_json")}"; do
    [[ -n $manifest ]] || continue
    local sides=()
    local ref
    for ref in "$base_sha" "$head_sha"; do
      sides+=("$(fetch_file "$manifest" "$ref" | jq -cS 'del(.dependencies, .devDependencies, .peerDependencies, .optionalDependencies, .require, .["require-dev"], .version)' || print unreadable-$ref)")
    done
    [[ ${sides[1]} == "${sides[2]}" ]] || print -r -- "$manifest"
  done
}

# Print true when, file by file and in order, a diff's removed lines equal its
# added lines once indentation, runs of spaces, quote style and a trailing
# comma or semicolon are ignored. Anything else (a moved statement, a
# re-wrapped line, a changed literal) is not provably formatting.
is_formatter_rewrite() {
  local sides=$work_dir/format.$RANDOM
  awk -v removed="$sides.removed" -v added="$sides.added" '
    /^diff --git / { file = $0; next }
    /^(\+\+\+|---) / { next }
    /^[+-]/ {
      line = substr($0, 2)
      gsub(/[ \t]+/, " ", line); sub(/^ /, "", line); sub(/ $/, "", line); sub(/[,;]$/, "", line); gsub(/\047/, "\"", line)
      if (line != "") print file "\t" line > (substr($0, 1, 1) == "-" ? removed : added)
    }' "$1"
  if [[ -s $sides.removed ]] && cmp -s "$sides.removed" "$sides.added"; then print true; else print false; fi
}

# Print true when everything the PR changes outside the package files is a
# rewrite by the formatter or linter it bumps.
check_formatter_output() {
  jq -e "$jq_defs"'any(.[]; .name | formatter)' <<<"$package_list" >/dev/null || { print false; return; }

  gh_read pr diff "$pr" >"$work_dir/pr.diff" || { print false; return; }
  # Keep every file that is not a package file.
  awk '
    /^diff --git / { skip = ($0 ~ /(composer\.json|composer\.lock|package\.json|package-lock\.json|yarn\.lock|pnpm-lock\.yaml)$/) }
    !skip { print }
  ' "$work_dir/pr.diff" >"$work_dir/other.diff"
  is_formatter_rewrite "$work_dir/other.diff"
}

# Print what the head lockfile changed against the base one.
# shortcut: `duplicates_new` only watches packages an app must hold one copy
# of; extend the list when a repo shares another singleton.
diff_lockfiles() {
  jq -n "$jq_defs"'
    def versions_by_name: group_by(.name) | map({key: .[0].name, value: (map(.version) | unique)}) | from_entries;
    ($base[0].packages | versions_by_name) as $old
    | ($head[0].packages | versions_by_name) as $new
    | ($base[0].direct | versions_by_name) as $old_direct
    | ($head[0].direct | versions_by_name) as $new_direct
    | ($base[0].packages | group_by(.name) | map({key: .[0].name, value: {
        hosts: (map(.host | select(. != null)) | unique), install_code: any(.[]; .install_code)}}) | from_entries) as $old_meta
    | {
        direct_moves: [$head[0].direct[] | . as $entry
          | select(($old_direct[$entry.name] // []) | index($entry.version) | not)
          | {name, from: ((($old_direct[.name] // []) - ($new_direct[.name] // [])) | first // null), to: .version, dev}],
        moved_total: ([$new | to_entries[] | select($old[.key] != .value)] | length),
        added: [$new | keys[] | select($old[.] == null)],
        host_changes: [$head[0].packages[] | select(.host != null) | . as $package
          | ($old_meta[.name].hosts // []) as $hosts
          | select(($hosts | length) > 0 and ($hosts | index($package.host) | not))
          | {name, from: $hosts, to: .host}] | unique,
        install_code_new: [$head[0].packages[] | select(.install_code and ($old_meta[.name].install_code != true)) | .name] | unique,
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

  # Page back until the release of $from itself turns up or the list ends. A
  # lower version alone proves nothing: a maintenance branch publishes old
  # version numbers next to the newest ones.
  local tmp page reached_start=false
  tmp=$(mktemp -d "$work_dir/notes.XXXXXX")
  : >"$tmp/releases.jsonl"
  for page in {1..10}; do
    gh_read api "repos/$repo/releases?per_page=100&page=$page" --jq '.[] | {tag_name, body}' >"$tmp/page.jsonl" || return 1
    [[ -s $tmp/page.jsonl ]] || { reached_start=true; break; }
    cat "$tmp/page.jsonl" >>"$tmp/releases.jsonl"
    if jq -es "$jq_defs"'($from | semver) as $old | $old != null
        and any(.[]; (.tag_name | tag_version($package)) as $tag | $tag != null and $tag.nums == $old.nums)' \
        --arg from "$from" --arg package "$package" "$tmp/page.jsonl" >/dev/null; then
      reached_start=true
      break
    fi
  done
  [[ $reached_start == true ]] || return 1

  local notes
  notes=$(jq -rs "$jq_defs"'
    ($from | semver) as $old | ($to | semver) as $new
    | if $old == null or $new == null then error("unreadable version") else . end
    | [.[] | (.tag_name | tag_version($package)) as $tag
        | select($tag != null and $tag.pre == "" and $tag.nums <= $new.nums
            and ($tag.nums > $old.nums or ($old.pre != "" and $tag.nums == $old.nums)))
        | . + {nums: $tag.nums}]
    | sort_by(.nums)
    | map("## \(.tag_name)\n\(.body // "")") | join("\n\n")
  ' --arg from "$from" --arg to "$to" --arg package "$package" "$tmp/releases.jsonl") || return 1
  [[ -n $notes ]] || return 1

  # Drop what carries no change: the author and link tail of each line, which
  # doubles the size, and the first-contribution list.
  # e.g. "* Fix clone() on relations by @someone in https://github.com/…/pull/1"
  notes=$(sed -E 's/ by @[^ ]+ in https:[^ ]+$//; /^\*\*Full Changelog\*\*/d; /made their first contribution/d; /^#+ *New Contributors/d' <<<"$notes")

  mkdir -p "${cached:h}"
  print -r -- "$notes" >"$tmp/notes.md"
  mv "$tmp/notes.md" "$cached"
  print -r -- "$notes"
}

# Print notes cut to $limit characters as {text, cut, omitted_lines}. Headings
# and every line that may describe a break stay; of the rest, the newest
# releases are kept first, since the notes run oldest to newest.
fit_notes() {
  local limit=$1
  jq -Rs --argjson limit "$limit" '
    def may_break: test("^#{1,6} ") or test("break|deprecat|remov|renam|default|secur|cve-|ghsa-|migrat|upgrad|drop|requir|no longer|minimum|behaviou?r|incompatib|instead of|must "; "i");
    if length <= $limit then {text: ., cut: false, omitted_lines: 0}
    else
      [split("\n") | to_entries[] | {index: .key, line: .value, keep: (.value | may_break)}] as $rows
      | (reduce ($rows | reverse[]) as $row ({size: ($rows | map(select(.keep) | (.line | length) + 1) | add // 0), extra: {}};
          if ($row.keep | not) and .size + ($row.line | length) + 1 <= $limit
          then .size += ($row.line | length) + 1 | .extra[$row.index | tostring] = true else . end)) as $fill
      | [$rows[] | select(.keep or $fill.extra[.index | tostring])] as $kept
      | {
          text: ($kept | map(.line) | join("\n") | .[0:$limit]),
          cut: true,
          omitted_lines: (([$rows[] | select(.line | test("\\S"))] | length) - ([$kept[] | select(.line | test("\\S"))] | length))
        }
    end'
}

# Print where the working tree uses a package: how many files, how many of
# them are runtime code, the first ten, and the symbols or import statements
# it takes, so release notes can be matched against them without another
# search. The full file list goes to $4 for later checks.
find_usage() {
  local ecosystem=$1 package=$2 namespaces=$3 files_out=$4 files symbols

  if [[ $ecosystem == composer ]]; then
    [[ -n $namespaces ]] || { : >"$files_out"; print '{"status": "unknown"}'; return; }
    local namespace literal=() escaped=()
    for namespace in "${(@f)namespaces}"; do
      literal+=(-e "$namespace")
      escaped+=("${namespace//\\/\\\\}")
    done
    files=$(rg -l -F "${literal[@]}" -g '*.php' . 2>/dev/null || true)
    symbols=$(rg -o --no-filename -g '*.php' "(${(j:|:)escaped})[A-Za-z0-9_\\\\]+" . 2>/dev/null | sort | uniq -c | sort -rn | head -40 | awk '{print $2}' || true)
  else
    # Every way a module is pulled in: import and export … from, a bare
    # side-effect import, a dynamic import, require, and a CSS @import.
    local spec="['\"]${package//./\\.}(/[^'\"]*)?['\"]"
    local globs=(-g '*.{ts,tsx,js,jsx,mjs,cjs,vue,svelte,css,scss}')
    files=$(rg -l "${globs[@]}" "(from|import|require\\(|import\\()\\s*${spec}" . 2>/dev/null || true)
    # An import list often spans lines, so match across them and fold each
    # statement onto one line.
    symbols=$(rg --json -oU "${globs[@]}" "(import|export)\\s[^;'\"]*?from\\s*${spec}|(import|require)\\(?\\s*${spec}" . 2>/dev/null \
      | jq -r 'select(.type == "match") | .data.submatches[].match.text | gsub("\\s+"; " ")' | sort -u | head -40 || true)
  fi

  print -r -- "$files" >"$files_out"
  jq -n --arg files "$files" --arg symbols "$symbols" '
    ($files | split("\n") | map(select(. != ""))) as $all
    | {
        status: "ok",
        file_count: ($all | length),
        # Files outside tests, stories and tool config are what ships.
        runtime_file_count: ($all | map(select(test("(^|/)(tests?|__tests__|e2e|cypress|stories|\\.storybook)/|\\.(test|spec|stories)\\.[a-z]+$|(^|/)[^/]*\\.config\\.[a-z]+$") | not)) | length),
        files: ($all | .[0:10]),
        symbols: ($symbols | split("\n") | map(select(. != "")))
      }'
}

# Print the config, view and migration files an upstream range changed that
# the working tree holds a published copy of.
find_published_resources() {
  local repo=$1 old_ref=$2 new_ref=$3 changed

  changed=$(gh_read api "repos/$repo/compare/$old_ref...$new_ref" --jq '[.files[].filename]') || { print '{"status": "unknown"}'; return; }

  local published=() file migration
  for file in "${(@f)$(jq -r '.[] | select(test("^(config/|resources/views/|database/migrations/)"))' <<<"$changed")}"; do
    [[ -n $file ]] || continue
    if [[ $file == config/* && -f config/${file:t} ]]; then
      published+=("$file")
    elif [[ $file == resources/views/* && -n $(print -l resources/views/vendor/*/${file#resources/views/}(N)) ]]; then
      published+=("$file")
    elif [[ $file == database/migrations/* ]]; then
      # A package ships a migration as a stub; the published copy drops the
      # ".stub" and takes a new date prefix.
      migration=${${file:t}%.stub}
      [[ -n $(print -l database/migrations/*${migration#*_*_*_*_}(N)) ]] && published+=("$file")
    fi
  done

  # GitHub's compare lists at most 300 files, so a longer range is incomplete.
  jq -n --argjson changed "$changed" --args '{
    status: (if ($changed | length) >= 300 then "truncated" else "ok" end),
    shadowed: $ARGS.positional
  }' "${published[@]}"
}

# Print one published npm version's registry record. A published version never
# changes, so one lookup per version is kept for good.
npm_record() {
  local cached=$cache_dir/npm/$1@$2.json

  if [[ ! -s $cached ]]; then
    mkdir -p "${cached:h}"
    npm view "$1@$2" --json 2>/dev/null >"$cached.$$" && [[ -s $cached.$$ ]] || { rm -f "$cached.$$"; return 1; }
    mv "$cached.$$" "$cached"
  fi
  cat "$cached"
}

# Print what a registry record asks of the app: the runtime, the peers it
# does not mark optional (an unmet optional peer is not a conflict), the module
# type, and the subpaths it exports.
npm_requirements() {
  jq '(.peerDependenciesMeta // {}) as $meta
    | {
        engines: (.engines // {}),
        peers: ((.peerDependencies // {}) | with_entries(select($meta[.key].optional != true))),
        type: (.type // "commonjs"),
        exports: (.exports | if type == "object" then (keys | map(select(startswith(".")))) else [] end)
      }' "$1"
}

# Print one package's evidence as a JSON object. The lookups that wait on the
# network run side by side; each leaves a ".ok" file when it succeeded, so a
# failed one becomes "unknown" and never an empty result.
collect_package() {
  local package_json=$1 tmp
  tmp=$(mktemp -d "$work_dir/package.XXXXXX")

  local name from to bump named repo old_ref new_ref namespaces description
  IFS=$'\x1f' read -r name from to bump named repo old_ref new_ref < <(
    jq -r '[.name, .from // "", .to, .bump, .named, .repo // "", .old_ref // "", .new_ref // ""] | map(tostring) | join("\u001f")' <<<"$package_json")
  namespaces=$(jq -r '.namespaces | join("\n")' <<<"$package_json")
  description=$(jq -r '.description // ""' <<<"$package_json")

  # Advisories: what the old and the new version each carry. A package the
  # bump adds has no old version, so only the new one is looked up.
  if [[ -n $from ]]; then
    { list_advisories "$ecosystem" "$name" "$from" >"$tmp/advisories-old" && : >"$tmp/advisories-old.ok" } &
  else
    : >"$tmp/advisories-old"; : >"$tmp/advisories-old.ok"
  fi
  { list_advisories "$ecosystem" "$name" "$to" >"$tmp/advisories-new" && : >"$tmp/advisories-new.ok" } &

  # A pnpm lockfile does not say where a package's source lives or what it
  # is for; the registry does.
  if [[ $ecosystem == npm ]]; then
    [[ -n $from ]] && { npm_record "$name" "$from" >"$tmp/npm-old" && : >"$tmp/npm-old.ok" } &
    if npm_record "$name" "$to" >"$tmp/npm-new"; then
      : >"$tmp/npm-new.ok"
      [[ -n $repo ]] || repo=$(jq -r '.repository.url? // .repository // "" | strings' "$tmp/npm-new" | github_repo_from_url || true)
      [[ -n $description ]] || description=$(jq -r '.description // ""' "$tmp/npm-new")
    fi
  fi

  if [[ -n $repo && -n $from ]]; then
    { fetch_release_notes "$name" "$repo" "$from" "$to" >"$tmp/notes" && : >"$tmp/notes.ok" } &
  fi

  local published='{"status": "not-applicable"}'
  if [[ $ecosystem == composer && $bump != patch && -n $repo && -n $old_ref && -n $new_ref ]]; then
    find_published_resources "$repo" "$old_ref" "$new_ref" >"$tmp/published" &
  fi

  local usage
  usage=$(find_usage "$ecosystem" "$name" "$namespaces" "$tmp/usage-files")

  wait
  [[ -s $tmp/published ]] && published=$(<"$tmp/published")

  # A fixed advisory may name the vulnerable functions: note which of the
  # files that use the package call one, so exposure needs no further search.
  local advisories='{"status": "unknown"}'
  if [[ -e $tmp/advisories-old.ok && -e $tmp/advisories-new.ok ]]; then
    advisories=$(jq -n --rawfile old "$tmp/advisories-old" --rawfile new "$tmp/advisories-new" '
      ([$old | split("\n")[] | select(. != "") | fromjson]) as $before
      | ([$new | split("\n")[] | select(. != "") | fromjson]) as $after
      | ($before | map(.id)) as $before_ids | ($after | map(.id)) as $after_ids
      | {
          status: "ok",
          introduced: [$after[] | select(.id as $id | $before_ids | index($id) | not)],
          fixed: [$before[] | select(.id as $id | $after_ids | index($id) | not)],
          still_open: [$after[] | select(.id as $id | $before_ids | index($id))]
        }')
    local function_name hits='{}'
    for function_name in "${(@f)$(jq -r '[.fixed[].vulnerable_functions[]] | unique[]' <<<"$advisories")}"; do
      # e.g. "Vendor\Writer\Html::generateRow()" → search for "generateRow"
      local identifier=${${function_name%%\(*}##*[^A-Za-z0-9_]}
      [[ -n $identifier && -s $tmp/usage-files ]] || continue
      hits=$(jq --arg name "$function_name" --arg files "$(tr '\n' '\0' <"$tmp/usage-files" | xargs -0 rg -lw -F -- "$identifier" 2>/dev/null | head -5 || true)" \
        '. + {($name): ($files | split("\n") | map(select(. != "")))}' <<<"$hits")
    done
    advisories=$(jq --argjson hits "$hits" '.fixed |= map(. + {used_in: ([.vulnerable_functions[] | $hits[.] // []] | add // [] | unique)})' <<<"$advisories")
  fi

  # Release notes: upstream releases for the range, else Dependabot's PR body
  # for a package the PR names.
  local notes='' notes_source=missing
  if [[ -e $tmp/notes.ok ]]; then
    notes=$(<"$tmp/notes")
    notes_source=releases
  elif [[ $named == true ]] && grep -qiE 'release notes|changelog' <<<"$pr_body"; then
    # Dependabot's own footer and badge say nothing about the package.
    notes=$(sed -E 's/<[^>]+>//g' <<<"$pr_body" | sed -E '/Dependabot compatibility score/d; /^Dependabot will resolve any conflicts/,$d' | grep -v '^[[:space:]]*$' || true)
    notes_source=pr-body
  fi
  # Dependabot marks a PR body it cut short; that is a gap in the notes.
  local notes_truncated=false
  [[ $notes_source == pr-body ]] && grep -q '(truncated)' <<<"$notes" && notes_truncated=true
  # 40000 characters is about 10k tokens; a longer range is cut to fit.
  local fitted
  fitted=$(print -rn -- "$notes" | fit_notes 40000)

  # Runtime floor and entry points: only what changed between the versions.
  # A patch bump compares the engines the lockfile records; a larger one
  # compares the registry records, which also hold peers and exports.
  local requirements
  requirements=$(jq '{status: (if .old_requires == .new_requires then "unchanged" else "changed" end)}
    + (if .old_requires == .new_requires then {} else {old: .old_requires, new: .new_requires} end)' <<<"$package_json")
  if [[ $ecosystem == npm && $bump != patch && -n $from ]]; then
    if [[ -e $tmp/npm-old.ok && -e $tmp/npm-new.ok ]]; then
      requirements=$(jq -n --argjson old "$(npm_requirements "$tmp/npm-old")" --argjson new "$(npm_requirements "$tmp/npm-new")" '
        ($old.exports - $new.exports) as $removed
        | if ($old | del(.exports)) == ($new | del(.exports)) and ($removed | length) == 0 then {status: "unchanged"}
          else {status: "changed", old: ($old | del(.exports)), new: ($new | del(.exports)), removed_exports: $removed} end')
    else
      requirements='{"status": "unknown"}'
    fi
  fi

  jq -n --argjson package "$package_json" --argjson advisories "$advisories" --argjson usage "$usage" \
    --argjson requirements "$requirements" --argjson published "$published" --argjson fitted "$fitted" \
    --arg notes_source "$notes_source" --argjson notes_truncated "$notes_truncated" --arg repo "$repo" --arg description "$description" "$jq_defs"'
    ($package | del(.old_requires, .new_requires, .namespaces, .old_ref, .new_ref)) + {
      repo: (if $repo == "" then null else $repo end),
      description: (if $description == "" then null else $description end),
      test_only: ($package.dev and ($package.name | test_only)),
      advisories: $advisories,
      usage: $usage,
      requirements: $requirements,
      published_resources: $published,
      notes: {source: $notes_source, truncated: $notes_truncated, cut: $fitted.cut, omitted_lines: $fitted.omitted_lines, text: $fitted.text}
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
    [(.statusCheckRollup // []) | group_by([.workflowName // "", .name // .context])[]
      | {job: (.[0].name // .[0].context), workflow: (.[0].workflowName // null), result: result,
         job_id: ([.[] | select((.conclusion // "") | IN("FAILURE", "TIMED_OUT", "STARTUP_FAILURE")) | .detailsUrl // "" | capture("/job/(?<id>[0-9]+)").id?] | first // null)}]
  ' <<<"$pr_json"
}

# Print one failed job's evidence: whether the same job passes on the base
# branch, the failing lines of its log, and a fingerprint of them so PRs that
# fail the same way can share one investigation.
collect_failed_job() {
  local job=$1 job_id=$2 base_checks=$3 base_result=unknown log='' failing='' errors=''

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
    # A job that fails outside a test runner (type check, lint, build,
    # install, a PHP fatal) prints no test header; take its error lines.
    if [[ -z $failing$errors ]]; then
      errors=$(grep -E 'error TS[0-9]+|^[[:space:]]*[0-9]+:[0-9]+[[:space:]]+error|Fatal error|PHP (Parse|Fatal)|npm (ERR!|error)|ERR_[A-Z_]+|^[[:space:]]*(Error|ERROR)[: ]|##\[error\]' <<<"$log" | sed -E 's/[[:space:]]+/ /g' | awk '!seen[$0]++' | head -10 | cut -c1-400 || true)
    fi
  fi

  local fingerprint=''
  [[ -n $failing$errors ]] && fingerprint=$(print -r -- "$failing$errors" | sed -E 's/[0-9]+(\.[0-9]+)?s//g' | shasum | cut -c1-12)

  jq -n "$jq_defs"' {
    job: $job,
    base_branch_result: $base,
    fingerprint: (if $fingerprint == "" then null else $fingerprint end),
    failing_tests: ($failing | split("\n") | map(select(. != ""))),
    errors: ($errors | split("\n") | map(select(. != "")))
  } | .network_only = network_only' --arg job "$job" --arg base "$base_result" --arg failing "$failing" --arg errors "$errors" --arg fingerprint "$fingerprint"
}

# Print the evidence of every failed job as a JSON array.
collect_failed_jobs() {
  local failed_jobs='[]' base_checks failed_job

  jq -e 'any(.[]; .result == "failed")' <<<"$ci_jobs" >/dev/null || { print '[]'; return; }
  base_checks=$(gh_read api --paginate "repos/{owner}/{repo}/commits/$base_branch/check-runs?per_page=100" --jq '.check_runs[] | {name, conclusion}' | jq -s '.') || base_checks=''
  for failed_job in "${(@f)$(jq -c '.[] | select(.result == "failed")' <<<"$ci_jobs")}"; do
    failed_jobs=$(jq --argjson job "$(collect_failed_job "$(jq -r '.job' <<<"$failed_job")" "$(jq -r '.job_id // ""' <<<"$failed_job")" "$base_checks")" '. + [$job]' <<<"$failed_jobs")
  done
  print -r -- "$failed_jobs"
}

# Collect several PRs side by side, four at a time, and print one line per PR
# with what decides the next step.
collect_many() {
  local out_dir=$1 pr running=0
  shift
  mkdir -p "$out_dir"

  for pr in "$@"; do
    "$script_path" "$pr" >"$out_dir/ev-$pr.json" 2>"$out_dir/ev-$pr.log" &
    (( ++running % 4 == 0 )) && wait
  done
  wait

  print -u2 -- '--------- Result ---------'
  for pr in "$@"; do
    jq -r '"\(.pr)\t" + (if .supported | not then "unsupported: \(.reason)"
      elif .ci_wait then "ci still running"
      else "tier=\(.tier)\tfloor=\(.floor)\tauto=\(.auto)\tfingerprint=\([.ci.failed[] | select(.base_branch_result == "passed" and (.network_only | not)) | .fingerprint] | first // "-")" end)' \
      "$out_dir/ev-$pr.json" 2>/dev/null | grep . || print -- "$pr\tfailed: see $out_dir/ev-$pr.log"
  done
}

if [[ ${1:-} == --out-dir ]]; then
  collect_many "${@:2}"
  exit
fi

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

if [[ ${1:-} == --self-check ]]; then
  self_check
  exit
fi

# Parsed lockfiles are only useful while their PRs are open.
find "$cache_dir/lockfiles" -type f -mtime +7 -delete 2>/dev/null || true

# 1. Read the PR once, so every check sees the same head commit. Stop here
#    when CI is still running: the assessment waits for it anyway.
pr_json=$(gh_read pr view "$1" --json number,title,body,url,author,baseRefName,baseRefOid,headRefOid,files,changedFiles,commits,statusCheckRollup)
pr=$(jq -r '.number' <<<"$pr_json")
head_sha=$(jq -r '.headRefOid' <<<"$pr_json")
base_sha=$(jq -r '.baseRefOid' <<<"$pr_json")
base_branch=$(jq -r '.baseRefName' <<<"$pr_json")
pr_body=$(jq -r '.body' <<<"$pr_json")

lockfiles=("${(@f)$(jq -r '.files[].path | select(test("(^|/)(composer\\.lock|pnpm-lock\\.yaml|package-lock\\.json|yarn\\.lock)$"))' <<<"$pr_json")}")
lockfiles=(${lockfiles:#})
non_package_files=$(jq -c '[.files[].path | select(test("(^|/)(composer\\.json|composer\\.lock|package\\.json|package-lock\\.json|yarn\\.lock|pnpm-lock\\.yaml)$") | not)]' <<<"$pr_json")
file_list_complete=$(jq '.changedFiles == (.files | length)' <<<"$pr_json")

# Print the reason this PR needs the by-hand assessment, and stop.
report_unsupported() {
  jq -n --argjson pr "$pr" --arg head "$head_sha" --arg reason "$1" --argjson files "$non_package_files" \
    '{pr: $pr, head_sha: $head, supported: false, reason: $reason, non_package_files: $files}'
  exit
}

(( ${#lockfiles} == 0 )) && report_unsupported 'no lockfile in the diff'
(( ${#lockfiles} > 1 )) && report_unsupported "the PR changes ${#lockfiles} lockfiles: ${(j:, :)lockfiles}"
lockfile=${lockfiles[1]}
[[ $lockfile == *yarn.lock ]] && report_unsupported 'yarn.lock has no reader'
ecosystem=npm
[[ $lockfile == *composer.lock ]] && ecosystem=composer

ci_jobs=$(summarise_ci)
if jq -e 'any(.[]; .result == "pending")' <<<"$ci_jobs" >/dev/null; then
  jq -n --argjson pr "$pr" --arg head "$head_sha" --argjson ci "$ci_jobs" \
    '{pr: $pr, head_sha: $head, supported: true, ci_wait: true, ci: {pending: [$ci[] | select(.result == "pending") | .job]}}'
  exit
fi

# 2. Compare the base and head lockfiles.
read_lockfile "$lockfile" "$base_sha" >"$work_dir/base.json" &
base_reader=$!
read_lockfile "$lockfile" "$head_sha" >"$work_dir/head.json" &
head_reader=$!
wait $base_reader
wait $head_reader
lock_diff=$(diff_lockfiles "$work_dir/base.json" "$work_dir/head.json")

# 3. List the packages to assess: the ones the PR names, plus every direct
#    dependency the lockfile moves.
named_packages=$(jq -r '.commits[].messageBody' <<<"$pr_json" | named_from_trailer)
package_list=$(jq -n "$jq_defs"'
  ($named | split("\n") | map(select(. != ""))) as $names
  | ($diff.direct_moves | map(.name)) as $moved
  | ($base[0].packages | group_by(.name) | map({key: .[0].name, value: .}) | from_entries) as $old_by_name
  | ($head[0].packages | group_by(.name) | map({key: .[0].name, value: .}) | from_entries) as $new_by_name
  | [($names + $moved | unique)[] as $name
    | ($diff.direct_moves | map(select(.name == $name)) | first) as $move
    | ($old_by_name[$name] // []) as $old | ($new_by_name[$name] // []) as $new
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
        namespaces: ($new_entry.namespaces // []),
        description: ($new_entry.description // null),
        old_requires: ($old_entry.requires // {}), new_requires: ($new_entry.requires // {})
      }]
' --arg named "$named_packages" --argjson diff "$lock_diff" --slurpfile base "$work_dir/base.json" --slurpfile head "$work_dir/head.json")

[[ $package_list == '[]' ]] && report_unsupported 'the lockfile moves no package the PR names and no direct dependency'

manifest_edits=$(list_manifest_edits | jq -Rsc 'split("\n") | map(select(. != ""))')
formatter_only=false
[[ $non_package_files != '[]' ]] && formatter_only=$(check_formatter_output)

# 5. Read CI: for a failed job the base branch's result and the failing lines
#    of its log. It runs beside step 4, since neither waits on the other.
collect_failed_jobs >"$work_dir/failed.json" &
ci_reader=$!

# 4. Per package: advisories, release notes, usage, runtime floor, entry
#    points, published Laravel resources. Four packages at a time, so a
#    grouped PR stays under GitHub's limit on parallel requests.
package_readers=()
index=0
for package_json in "${(@f)$(jq -c '.[]' <<<"$package_list")}"; do
  # Counted here, not in the redirect: that would run in the child.
  (( index += 1 ))
  collect_package "$package_json" >"$work_dir/package-$index.json" &
  package_readers+=($!)
  if (( index % 4 == 0 )); then
    for reader in $package_readers; do wait $reader; done
    package_readers=()
  fi
done
for reader in $package_readers; do wait $reader; done
packages=$(jq -s '.' "$work_dir"/package-<->.json(n))

wait $ci_reader
failed_jobs=$(<"$work_dir/failed.json")

# 6. Apply the mechanical rules and print the evidence as JSON.
# shortcut: the jobs for an ecosystem are recognised by name; a repo whose job
# names match neither pattern reports `ecosystem_jobs: "unknown"` and leaves
# the question to the judge.
print -u2 -- '--------- Result ---------'
jq -n "$jq_defs"'
  def level_rank: {"Low": 0, "Medium": 1, "High": 2}[.];
  (if $ecosystem == "composer" then "backend|php|pest|phpunit|laravel|composer" else "frontend|front-end|node|vite|vitest|jest|build|pnpm|npm" end) as $job_pattern
  | ($ci | map(select(.job | test($job_pattern; "i")))) as $ecosystem_jobs
  | ($packages | map(.bump | bump_rank) | max // 3) as $largest
  | ($failed | map(select(.base_branch_result == "passed" and (.network_only | not)))) as $bump_caused
  | ($failed | map(select(.base_branch_result == "passed" and .network_only))) as $network_failed
  | {
      pr: $pr, head_sha: $head, base_branch: $base_branch, ecosystem: $ecosystem, lockfile: $lockfile, supported: true,
      tier: (["patch", "patch", "minor", "major"][$largest]),
      packages: $packages,
      lockfile_changes: ($diff | del(.direct_moves) + {unnamed_direct_moves: [$packages[] | select(.direct and (.named | not)) | "\(.name) \(.from) → \(.to)"]}),
      non_package_files: $non_package_files,
      formatter_only: $formatter_only,
      manifest_edits: $manifest_edits,
      ci: ({
        passed: ($ci | map(select(.result == "passed")) | length),
        pending: [],
        cancelled: [$ci[] | select(.result == "cancelled") | .job],
        skipped: ($ci | map(select(.result == "skipped")) | length),
        failed: $failed,
        ecosystem_jobs: (if ($ecosystem_jobs | length) == 0 then "unknown"
          elif any($ecosystem_jobs[]; .result == "passed" or .result == "failed") then "ran"
          else "skipped" end)
      } | if .ecosystem_jobs == "unknown" then .jobs = [$ci[] | "\(.job): \(.result)"] else . end),
      api_calls: $api_calls
    }
  | .rules = [
      {id: "advisory-introduced", level: "High", fired: any($packages[]; (.advisories.introduced // []) | length > 0),
       evidence: ([$packages[] | .name as $name | (.advisories.introduced // [])[] | "\(.id) in \($name)"] | join(", "))},
      {id: "ci-red-bump-caused", level: "High", fired: (($bump_caused | length) > 0),
       evidence: (if ($bump_caused | length) > 0 then "\($bump_caused | map("`\(.job)`") | join(", ")) fails here, passes on `\($base_branch)`" else "" end)},
      {id: "advisory-lookup-failed", level: "Medium", fired: any($packages[]; .advisories.status != "ok"),
       evidence: ([$packages[] | select(.advisories.status != "ok") | .name] | join(", "))},
      {id: "ci-red-unresolved", level: "Medium", fired: any($failed[]; .base_branch_result != "passed"),
       evidence: ([$failed[] | select(.base_branch_result != "passed") | "`\(.job)` on base: \(.base_branch_result)"] | join(", "))},
      {id: "ci-red-network", level: "Medium", fired: (($network_failed | length) > 0),
       evidence: ([$network_failed[] | "`\(.job)` failed on a network error and passes on `\($base_branch)`: re-run it"] | join(", "))},
      {id: "ci-incomplete", level: "Medium", fired: (($ci | length) == 0 or (.ci.cancelled | length) > 0),
       evidence: (.ci.cancelled | map("`\(.)`") | join(", "))},
      {id: "ci-ecosystem-jobs-skipped", level: "Medium", fired: (.ci.ecosystem_jobs == "skipped"), not_applicable: (.ci.ecosystem_jobs == "unknown"), evidence: ""},
      {id: "diff-outside-package-files", level: "Medium",
       fired: ((($non_package_files | length) > 0 and ($formatter_only | not)) or ($manifest_edits | length) > 0 or ($file_list_complete | not)),
       evidence: (($non_package_files | .[0:5]) + ($manifest_edits | map("\(.) beyond dependency versions")) | map("`\(.)`") | join(", "))},
      {id: "lockfile-host-change", level: "Medium", fired: ($diff.host_changes | length > 0),
       evidence: ($diff.host_changes | map("\(.name) → \(.to)") | join(", "))},
      {id: "lockfile-install-code", level: "Medium", fired: ($diff.install_code_new | length > 0), evidence: ($diff.install_code_new | join(", "))},
      {id: "lockfile-duplicate-copy", level: "Medium", fired: ($diff.duplicates_new | length > 0), evidence: ($diff.duplicates_new | join(", "))},
      {id: "downgrade", level: "Medium", fired: any($packages[]; .bump == "downgrade"),
       evidence: ([$packages[] | select(.bump == "downgrade") | "\(.name) \(.from) → \(.to)"] | join(", "))},
      # A test-only dev dependency skips the release-note rule; one that
      # shapes the build does not.
      ({id: "notes-missing", level: "Medium",
        evidence: ([$packages[] | select((.test_only | not) and (.bump | bump_rank) >= 2 and .notes.source == "missing") | .name] | join(", "))}
        | .fired = (.evidence != "")),
      # Notes cut to fit, or cut short by Dependabot, do not cover the range.
      ({id: "notes-incomplete", level: "Medium",
        evidence: ([$packages[] | select((.test_only | not) and (.bump | bump_rank) >= 2 and (.notes.cut or .notes.truncated)) | "\(.name): \(.notes.source) notes cut"] | join(", "))}
        | .fired = (.evidence != "")),
      {id: "published-resource-changed", level: "Medium", fired: any($packages[]; (.published_resources.shadowed // []) | length > 0),
       not_applicable: ($ecosystem != "composer"),
       evidence: ([$packages[] | (.published_resources.shadowed // [])[] | "`\(.)`"] | unique | join(", "))}
    ]
  | .floor = ([.rules[] | select(.fired) | .level] | max_by(level_rank) // "Low")
  # What still takes judgement; an empty list with a High floor needs none.
  | .judge = (if .floor == "High" then [] else [
      "notes-vs-usage",
      (if any($packages[]; .requirements.status != "unchanged") then "runtime-floor-and-entry-points" else empty end),
      (if any($packages[]; .published_resources.status | IN("unknown", "truncated")) then "published-resources" else empty end),
      (if .ci.ecosystem_jobs == "unknown" then "ci-jobs-for-ecosystem" else empty end)
    ] end)
  # A bump of test-only dev dependencies that passed every mechanical rule is
  # Low without a model: nothing it ships can change, and CI ran its jobs.
  | .auto = (.floor == "High" or (
      .floor == "Low" and .judge == ["notes-vs-usage"] and .ci.ecosystem_jobs == "ran" and $non_package_files == []
      and all($packages[]; .test_only and .advisories.status == "ok" and .usage.status == "ok" and .usage.runtime_file_count == 0
        and ([.advisories.fixed[] | select((.vulnerable_functions | length) > 0)] | length) == 0)))
  | .ci_wait = false
' --argjson pr "$pr" --arg head "$head_sha" --arg base_branch "$base_branch" --arg ecosystem "$ecosystem" --arg lockfile "$lockfile" \
  --argjson packages "$packages" --argjson diff "$lock_diff" --argjson ci "$ci_jobs" --argjson failed "$failed_jobs" \
  --argjson non_package_files "$non_package_files" --argjson file_list_complete "$file_list_complete" \
  --argjson manifest_edits "$manifest_edits" --argjson formatter_only "$formatter_only" --argjson api_calls "$(wc -c <"$work_dir/api_calls" | tr -d " ")"
