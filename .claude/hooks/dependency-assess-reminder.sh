#!/usr/bin/env bash
# PostToolUse hook on Bash: remind the agent to assess a PR's dependency changes.
#
# Agents open PRs and push follow-up commits without running
# custom-gh-dependabot-assess, even when the PR bumps or removes packages. A
# skill instruction alone gets skipped, so this hook checks after every
# `gh pr create`, `gh stack submit|push|sync`, or `git push` and tells the agent when an assessment is due.
#
# Flow:
#   1. Skip unless the command ran `gh pr create`, `gh stack submit|push|sync`, or `git push`.
#   2. Find the open PR for the current branch; skip when there is none.
#   3. List the manifests, lockfiles, and workflow `uses:` lines the PR changes; skip when none.
#   4. Compare the newest manifest commit with the existing assessment comment.
#   5. Print the reminder: assess when no comment exists, reassess when manifests changed after it.
#
# Exit is always 0; silence means no assessment is due or the check couldn't run.

MARKER='<!-- dependabot-assessment -->'
MANIFEST_RE='(^|/)(package\.json|package-lock\.json|npm-shrinkwrap\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?|composer\.json|composer\.lock)$'

command -v jq >/dev/null 2>&1 && command -v gh >/dev/null 2>&1 || exit 0

input=$(cat)

# --- 1. Only PR creation and pushes ---
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' | tr '\n' ' ')
[[ "$cmd" =~ (^|[^[:alnum:]_-])(gh[[:space:]]+pr[[:space:]]+create|gh[[:space:]]+stack[[:space:]]+(submit|push|sync)|git[[:space:]]+push)([^[:alnum:]_-]|$) ]] || exit 0

cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[[ -n "$cwd" ]] && cd "$cwd" 2>/dev/null
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# --- 2. Open PR for this branch ---
pr=$(gh pr view --json number,state,baseRefName 2>/dev/null) || exit 0
[[ $(jq -r '.state' <<<"$pr") == OPEN ]] || exit 0
number=$(jq -r '.number' <<<"$pr")
base=$(jq -r '.baseRefName' <<<"$pr")
git fetch --quiet origin "$base" 2>/dev/null || exit 0

# --- 3. Dependency files the PR changes ---
range="origin/$base...HEAD"
files=$(
  {
    git diff --name-only "$range" | rg "$MANIFEST_RE"
    git diff --name-only -G '^[[:space:]-]*uses:' "$range" -- .github/workflows
  } 2>/dev/null | sort -u
)
[[ -n "$files" ]] || exit 0

# --- 4. Newest manifest change vs. the assessment comment ---
# Author date survives a rebase, so rebasing onto the base branch doesn't re-trigger.
changed_at=$(git log -1 --format=%at "origin/$base..HEAD" -- $files 2>/dev/null)
assessed_at=$(gh api "repos/{owner}/{repo}/issues/$number/comments" --paginate \
  --jq ".[] | select(.body | contains(\"$MARKER\")) | .updated_at" 2>/dev/null | tail -n 1)

if [[ -z "$assessed_at" ]]; then
  action="run the custom-gh-dependabot-assess skill on PR #$number now"
elif [[ -n "$changed_at" ]] && (( changed_at > $(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$assessed_at" +%s 2>/dev/null || echo 0) )); then
  action="dependency files changed after the last assessment; run the custom-gh-dependabot-assess skill with \`$number reassess\` now"
else
  exit 0
fi

# --- 5. Reminder ---
jq -n --arg ctx "PR #$number changes dependency files ($(tr '\n' ' ' <<<"$files")): $action, before reporting the PR as done." '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'
exit 0
