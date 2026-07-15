# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Installation Verification

```bash
rtk --version         # Should show: rtk X.Y.Z
rtk gain              # Should work (not "command not found")
which rtk             # Verify correct binary
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code hook.
Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)

## Known trap: output filtering

rtk summarizes command output and can drop details you need (e.g. `rtk ls` strips timestamps). If output is missing expected detail, re-run the exact command as `rtk proxy <cmd>` to see raw output before changing approach. Empty results from `fd`/`rg` are usually NOT rtk — check ignore rules first (see CLI Tool Calling in AGENTS.md).

Refer to CLAUDE.md for full command reference.
