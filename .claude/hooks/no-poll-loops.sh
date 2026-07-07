#!/usr/bin/env bash
# PreToolUse hook on Bash: block busy-wait polling loops.
#
# The model sometimes "waits" for background work (Codex runs, CI, servers) by
# spinning in `until/while ...; do sleep N; done` inside a single Bash call.
# That blocks the whole turn with zero output until the Bash timeout kills it,
# which looks like a hang. Background tasks re-invoke the model on completion,
# so polling is never needed — deny the loop and say what to do instead.
#
# Composes with prefer-rg-fd.sh / rtk-rewrite.sh: each hook gets its own stdin
# copy, denials win.

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# Flatten to one line so the regex sees multi-line loops too.
flat=$(printf '%s' "$cmd" | tr '\n' ' ')

# A shell loop (while/until/for ... do ... done) whose body runs sleep.
if printf '%s' "$flat" | grep -qE '\b(while|until|for)\b.*[;&[:space:]]do\b.*\bsleep\b.*\bdone\b'; then
  jq -n --arg reason "Busy-wait polling loops are not allowed: they block the turn with no output until the Bash timeout kills them. Instead: (1) launch the long-running command with run_in_background: true and END YOUR TURN — the harness re-invokes you when it completes; (2) to check progress once, use a single bounded read like \`tail -n 50 <file>\` with no loop; (3) if you are intentionally writing a script file that contains a loop, create it with the Write tool, not a Bash heredoc." '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
fi

exit 0
