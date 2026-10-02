# Flow Video

Use a video when the point is the navigation itself: the sequence of pages, a transition, a loading state, a multi-step form. For a single changed screen, the screenshots are enough.

Record with `agent-browser`, not ego-browser. agent-browser runs a headless Chromium, so it doesn't open a window or take your screen. Its `record` command writes WebM. It needs `ffmpeg` on PATH (`brew "ffmpeg"` in the Brewfile). The `agent-browser` skill has the full command list. ego-browser has no record command. A CDP screencast through `page.cdp()` does return frames, but it runs in the visible ego window and you would have to encode the frames yourself.

## Script

Write `flow.sh` to the scratchpad so it can run again unchanged, for example against the base branch for a before video. A headless video has no OS cursor, so the script draws one: [../assets/cursor.js](../assets/cursor.js) adds an arrow that moves like a hand: curved paths with a fast start and long slowdown, a slight overshoot, a small drift off the control after a click, and a slow idle wander while the page is being read, so the arrow never freezes between steps. The page animates all of it: `window.__flowCursorGlideTo(x, y)` glides the arrow while the real pointer stays put, then one real `mouse move` lands the pointer on the arrow, so hover states start when the arrow arrives instead of before it. A motion that is perfectly efficient or perfectly still reads as a robot.

```zsh
#!/usr/bin/env zsh
# Records the <name> flow as a WebM for the PR description, with a screenshot per step for review.
#
# Flow:
#   1. Set the viewport and log in, before recording.
#   2. Start recording on the page where the flow begins, then inject the fake cursor.
#   3. Walk the flow: glide the cursor to each target, click it, wait for the expected state, pause, screenshot.
#   4. Stop recording, which writes the WebM.
#
# Exit 0 means every expected state appeared and flow.webm was written.
set -euo pipefail

out=${1:?usage: flow.sh <output-dir>}
cursor_script=~/.claude/skills/custom-user-flow-capture/assets/cursor.js
mkdir -p "$out"

# Runs agent-browser in a named session, so it doesn't touch other agent-browser sessions.
ab() { agent-browser --session flow-video "$@" < /dev/null; }
trap 'ab record stop >/dev/null 2>&1; ab close >/dev/null 2>&1' EXIT

# Injects the fake cursor; a no-op when the page already has it.
ensure_cursor() {
  ab eval "$(cat "$cursor_script")" >/dev/null
}

# Glides the cursor to a random point in the middle of the first visible <selector> element, optionally containing <text>.
# e.g. move_to '[role=menuitem]' 'View Document'
move_to() {
  local center
  center=$(ab eval "(() => {
    const element = [...document.querySelectorAll($(jq -n --arg v "$1" '$v'))]
      .find((candidate) => candidate.offsetParent !== null && candidate.textContent.includes($(jq -n --arg v "${2:-}" '$v')));
    const rect = element.getBoundingClientRect();
    return { x: Math.round(rect.x + rect.width * (0.35 + Math.random() * 0.3)), y: Math.round(rect.y + rect.height * (0.35 + Math.random() * 0.3)) };
  })()" --json)
  cursor_x=$(jq -er '.data.result.x' <<< "$center")
  cursor_y=$(jq -er '.data.result.y' <<< "$center")
  # glide the drawn arrow first; the real pointer follows on arrival, so hover starts when the arrow lands
  ab eval "window.__flowCursorGlideTo($cursor_x, $cursor_y)" >/dev/null
  wait_for_cursor
  ab mouse move $cursor_x $cursor_y >/dev/null
}

# Waits until the drawn arrow finishes its current motion.
wait_for_cursor() {
  ab wait --fn 'performance.now() >= (window.__flowCursorBusyUntil || 0)' >/dev/null
}

# Fails unless the drawn arrow sits on the real mouse position, so a click never shows as a teleport.
assert_cursor_on_target() {
  ab wait --fn "Math.hypot((window.__flowCursorAt?.x ?? -1e4) - $cursor_x, (window.__flowCursorAt?.y ?? -1e4) - $cursor_y) < 3" >/dev/null \
    || { echo "cursor did not reach $cursor_x,$cursor_y before the click" >&2; return 1; }
}

# Clicks <selector> (optionally containing <text>) with real mouse events, so the ripple shows where it lands.
click_at() {
  move_to "$1" "${2:-}"
  assert_cursor_on_target
  ab mouse down >/dev/null
  ab mouse up >/dev/null
  # the arrow eases off the control after a click; bring the real pointer along so hover ends with it
  wait_for_cursor
  local at
  at=$(ab eval '({ x: Math.round(window.__flowCursorAt.x), y: Math.round(window.__flowCursorAt.y) })' --json)
  ab mouse move $(jq -er '.data.result.x' <<< "$at") $(jq -er '.data.result.y' <<< "$at") >/dev/null
}

# Step 1: viewport and login, not recorded.
ab set viewport 1280 800
ab open http://localhost:8000/login
ab fill '#email' 'qa@example.test'
ab fill '#password' 'password'
ab click 'button[type=submit]'
ab wait --url '**/dashboard'

# Step 2: start recording, then show the cursor.
ab record start "$out/flow.webm"
ensure_cursor
ab wait 600

# Step 3: walk the flow, one block per step.
click_at 'a' 'Invoices'
ab wait --text 'Invoices'
ensure_cursor
ab wait 800
ab screenshot "$out/01-invoices.png"

# Step 4: stop recording.
ab record stop

echo '--------- Result ---------'
ls -l "$out"
```

- Set the viewport before `record start`. The video keeps the size it starts with.
- Do the login and setup before `record start`, so the video starts at the flow and doesn't show credentials. `record start` opens a fresh context that keeps cookies but not localStorage. Its help says it keeps both, but on 0.36 localStorage came back empty. If the app keeps its auth token in localStorage, put the login inside the recording.
- `record start` also drops scripts registered with `--init-script`, so inject the cursor with `eval` after it. Call `ensure_cursor` again after any step that loads a new document; a client-side route change keeps it.
- Move the real pointer only through `move_to` and `click_at`. A raw `ab mouse move` jumps the pointer ahead of the arrow, so hover styles and hover-opened menus show up before the arrow gets there.
- Click only through `click_at`. Its `assert_cursor_on_target` check fails the run when the drawn arrow didn't reach the target, which is what a click with no visible movement looks like in the video. A raw `ab click` or `ab mouse down` skips that check.
- Target elements through `move_to`, not agent-browser selectors: `get box` rejects Playwright-only selectors such as `:has-text()`, and `@eN` refs from `snapshot` change between runs.
- The fixed `wait 600` to `900` pauses go against the screenshot rule on purpose. They give the viewer time to read each state, and the idle wander keeps them from looking frozen. Still wait for the expected state first (`wait --text`, `wait --url`, `wait <selector>`), then pause.
- Stop the recording before `close`. The video is written on `record stop`.

Run it with `zsh <scratchpad>/flow.sh <scratchpad>/flow-<name>/after`.

## Review

You can't watch the WebM. Review the per-step screenshots as in the main workflow, then check the video itself:

```zsh
ffprobe -v error -show_entries format=duration -of csv=p=0 flow.webm
ffmpeg -v error -i flow.webm -vf fps=1 frame-%03d.png
```

The duration should match the script's waits. Read a few of the extracted frames to confirm the video shows the flow and not a blank page.

## Attach

GitHub plays `.webm` and `.mp4` inline in a PR description. Files must be under 10 MB on free plans. When the user asks to put it in the PR, upload it with `gh pr edit <pr> --attach '<path>#<alt text>'` (gh 2.102+). Without a body flag gh appends the video to the existing body. To place it at a spot in the body, reference it as `![alt](./flow.webm)` and pass `--body-file` with the same `--attach`; gh rewrites the link to the uploaded asset. If the file is too big, shrink it first:

```zsh
ffmpeg -i flow.webm -vf scale=960:-2 -c:v libx264 -crf 28 -an flow.mp4
```
