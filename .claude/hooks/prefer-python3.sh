#!/usr/bin/env bash
# PreToolUse hook on Bash: redirect bare `python` to `python3`.
#
# This Mac has no unversioned `python` binary, so bare `python` fails with
# exit 127 and the model burns a round trip discovering that. Deny it up
# front with the fix in the message. Do NOT express this as a permissions
# deny rule: the auto-mode classifier generalizes deny rules and starts
# blocking allowed `python3` calls as "circumvention" (seen 7x before the
# rule was removed in Aug 2026).
#
# Composes with the other Bash hooks: each gets its own stdin copy, denials win.

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# Analyze only real command positions, not prose: drop everything from the
# first heredoc marker (its body is data), and strip quoted spans per line,
# so text like `git commit -m "... python ..."` can't false-positive. A
# missed real invocation is fine — it just fails with exit 127 at runtime.
body="${cmd%%<<*}"
stripped=$(printf '%s\n' "$body" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")

# Split the command into pipelines by `;`, `&&`, `||`, `|`, then check the
# command word of each segment. Unlike grep/find, `python` is never a valid
# filter either, so every segment is checked.
while IFS= read -r segment; do
  # shellcheck disable=SC2206
  tokens=($segment)
  i=0
  while [ $i -lt ${#tokens[@]} ]; do
    tok="${tokens[$i]}"
    case "$tok" in
      *=*) i=$((i + 1)); continue ;;
      sudo|time|nice|env|command|builtin|exec|xargs) i=$((i + 1)); continue ;;
      *) break ;;
    esac
  done
  first_cmd="${tokens[$i]:-}"

  case "$first_cmd" in
    python | */bin/python)
      jq -n --arg reason "Use \`python3\` instead of \`python\`: this machine has no unversioned \`python\` binary, so the command would fail with exit 127. Rerun the identical command with \`python3\` (it is on the Bash allowlist)." '{
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason: $reason
        }
      }'
      exit 0
      ;;
  esac
done < <(printf '%s\n' "$stripped" | sed -E 's/(\&\&|\|\||;|\|)/\n/g')

exit 0
