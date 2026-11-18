#!/bin/zsh
# Decide whether a Dependabot PR meets the mechanical auto-merge conditions.
# They live in a script so that release notes and PR text, which an agent
# reads, cannot argue a PR past them.
#
# Usage: auto-merge-gate-for-dependabot-pr.sh <pr-number>
#        Run inside the repo checkout, or set GH_REPO=<owner>/<repo>.
#
# Steps:
#   1. Read the PR once, so the checks below see the same head commit.
#   2. Check the PR and every commit on it are Dependabot's.
#   3. Check every updated dependency is a patch bump.
#   4. Check only package manager files changed.
#   5. Check CI passed.
#
# Exit 0 proves every check passed for the head SHA on the last line. Merge
# only that SHA: gh pr merge <pr-number> --match-head-commit <sha>.
set -euo pipefail

pr=$1
gate_failed=0

# Run one check function and print its verdict; a failed check fails the gate.
check() {
  local name=$1 check_function=$2
  if "$check_function"; then
    print "PASS  $name"
    return
  fi

  print "FAIL  $name"
  gate_failed=1
}

# True when Dependabot opened the PR and authored every commit, so a human
# edit to a manifest never passes as a Dependabot bump.
# shortcut: trusts GitHub's author attribution, which a pusher can fake with Dependabot's commit email; check commit signatures if pushers aren't trusted
is_dependabot_authored() {
  jq -e '
    .author.login == "app/dependabot"
    and all(.commits[]; (.authors | length) > 0 and all(.authors[]; .login == "dependabot[bot]"))
  ' <<<"$pr_json" >/dev/null
}

# True when the commit trailer lists an update-type for every dependency and
# each one is semver-patch. A dependency with no update-type fails: Dependabot
# omits it on indirect and security bumps, and the size of those is unknown here.
# e.g. "  update-type: version-update:semver-patch"
is_patch_only() {
  local commit_bodies=$(jq -r '.commits[].messageBody' <<<"$pr_json")
  local dependencies=$(grep -c '^- dependency-name: ' <<<"$commit_bodies")
  local update_types=$(grep -c '^  update-type: ' <<<"$commit_bodies")
  local patches=$(grep -c '^  update-type: version-update:semver-patch$' <<<"$commit_bodies")

  [[ $dependencies -gt 0 && $dependencies -eq $update_types && $update_types -eq $patches ]]
}

# True when every changed file is a package manager manifest or lockfile.
# An incomplete file list must not pass, hence the count comparison.
is_manifest_only() {
  local manifests='composer\.json|composer\.lock|package\.json|package-lock\.json|yarn\.lock|pnpm-lock\.yaml'

  jq -e --arg manifests "$manifests" '
    .changedFiles == (.files | length)
    and all(.files[].path; test("(^|/)(" + $manifests + ")$"))
  ' <<<"$pr_json" >/dev/null
}

# True when the PR has at least one check and all of them passed; gh exits
# non-zero for failed, pending, and missing checks alike.
is_ci_green() {
  gh pr checks "$pr" >/dev/null 2>&1
}

# 1. Read the PR once, so the checks below see the same head commit.
pr_json=$(gh pr view "$pr" --json author,commits,files,changedFiles,headRefOid)
head_sha=$(jq -r '.headRefOid' <<<"$pr_json")

# 2. Check the PR and every commit on it are Dependabot's.
check 'dependabot-authored' is_dependabot_authored

# 3. Check every updated dependency is a patch bump.
check 'patch-only' is_patch_only

# 4. Check only package manager files changed.
check 'manifest-files-only' is_manifest_only

# 5. Check CI passed.
check 'ci-green' is_ci_green

print -- '--------- Result ---------'
if [[ $gate_failed -eq 0 ]]; then
  print "PASS  $head_sha"
  exit 0
fi

print "FAIL  $head_sha"
exit 1
