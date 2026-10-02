# Flow Video

Use a video when the point is the navigation itself: the sequence of pages, a transition, a loading state, a multi-step form. For a single changed screen, the screenshots are enough.

Record with `agent-browser`, not ego-browser. agent-browser runs a headless Chromium, so it doesn't open a window or take your screen. Its `record` command writes WebM. It needs `ffmpeg` on PATH (`brew "ffmpeg"` in the Brewfile). The `agent-browser` skill has the full command list. ego-browser has no record command. A CDP screencast through `page.cdp()` does return frames, but it runs in the visible ego window and you would have to encode the frames yourself.

## Script

Write `flow.sh` to the scratchpad so it can run again unchanged, for example against the base branch for a before video. Use CSS selectors, or the `find <strategy> <value> <action>` form (`find text "Save" click`). `@eN` refs from `snapshot` change between runs.

```zsh
#!/usr/bin/env zsh
# Records the <name> flow as a WebM for the PR description, with a screenshot per step for review.
#
# Flow:
#   1. Set the viewport and log in, before recording.
#   2. Start recording on the page where the flow begins.
#   3. Walk the flow: highlight, click, wait for the expected state, pause, screenshot.
#   4. Stop recording, which writes the WebM.
#
# Exit 0 means every expected state appeared and flow.webm was written.
set -euo pipefail

out=${1:?usage: flow.sh <output-dir>}
mkdir -p "$out"

# Runs agent-browser in a named session, so it doesn't touch other agent-browser sessions.
ab() { agent-browser --session flow-video "$@"; }
trap 'ab record stop >/dev/null 2>&1; ab close >/dev/null 2>&1' EXIT

# Step 1: viewport and login, not recorded.
ab set viewport 1280 800
ab open http://localhost:8000/login
ab fill '#email' 'qa@example.test'
ab fill '#password' 'password'
ab click 'button[type=submit]'
ab wait --url '**/dashboard'

# Step 2: start recording. It starts on the current page and keeps cookies but drops localStorage.
ab record start "$out/flow.webm"
ab wait 1000

# Step 3: walk the flow, one block per step.
ab highlight 'a[href="/invoices"]'
ab wait 600
ab click 'a[href="/invoices"]'
ab wait --text 'Invoices'
ab wait 1000
ab screenshot "$out/01-invoices.png"

# Step 4: stop recording.
ab record stop

echo '--------- Result ---------'
ls -l "$out"
```

- Set the viewport before `record start`. The video keeps the size it starts with.
- Do the login and setup before `record start`, so the video starts at the flow and doesn't show credentials. `record start` opens a fresh context that keeps cookies but not localStorage. Its help says it keeps both, but on 0.36 localStorage came back empty. If the app keeps its auth token in localStorage, put the login inside the recording.
- The fixed `wait 600` to `1000` pauses go against the screenshot rule on purpose. They give the viewer time to read each state. Still wait for the expected state first (`wait --text`, `wait --url`, `wait <selector>`), then pause.
- A headless video has no cursor. `highlight <selector>` before each click shows the viewer what gets clicked.
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
