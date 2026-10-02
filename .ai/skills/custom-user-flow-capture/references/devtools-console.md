# Capturing the DevTools console

Read this when the evidence lives in the browser console (an uncaught error, a failed chunk or module import, a warning the fix removes) rather than in the page.

## Why ego-browser alone can't do it

`page.screenshot()` captures only the page viewport; DevTools is never in it. Ego Lite can open DevTools only through a keyboard shortcut sent by macOS System Events, which needs Accessibility access for the terminal. Check with `osascript -e 'tell application "System Events" to get UI elements enabled'`. If that prints `true`, the shortcut route may work. It usually prints `false`, so use the fallback below. Ego Lite also exposes no remote-debugging port, so you can't load the DevTools frontend as a second tab either.

## Fallback: headed Playwright Chromium plus a window capture

1. Use the repo's own Playwright (`createRequire(<repo>/package.json)` then `require("@playwright/test")`). If its Chromium isn't downloaded, run `pnpm exec playwright install chromium`. Never drive the user's own Google Chrome: the window lookup below matches windows by app name and would grab one of theirs.
2. Launch with `chromium.launchPersistentContext(<fresh scratchpad profile>, { headless: false, viewport: null, ignoreHTTPSErrors: true, args: ["--auto-open-devtools-for-tabs", "--window-size=1280,1100"] })`. Before launching, write `<profile>/Default/Preferences` to set up DevTools. The values are JSON-encoded strings:
   ```json
   {"devtools":{"preferences":{
     "currentDockState":"\"bottom\"",
     "panel-selected-tab":"\"console\"",
     "preserve-console-log":"true"}}}
   ```
   Keep `preserve-console-log` on when the flow reloads or navigates. The error and the `Navigated to …` line that follows it are the evidence.
3. Capture only that window: `screencapture -x -o -l <windowId> <path>`. Get the id from `scripts/winid.swift`: compile it with `swiftc -O winid.swift -o <scratchpad>/winid`, then run `<scratchpad>/winid "Google Chrome for Testing"`. Never take a full-screen `screencapture`, because it records whatever else the user has open.
4. Wait briefly (under 1 s) before each capture so the console panel finishes painting. This is the one allowed fixed delay: nothing observable marks the moment DevTools has rendered.

## Simulating a failed fetch

To reproduce a network-dependent error on demand, block the resource over CDP (`Network.enable`, then `Network.setBlockedURLs` with a glob), and unblock it again to show recovery. Before you rely on a real redeploy to produce the failure, check whether the framework already recovers from a changed asset version by doing a full-page visit (Inertia does). If it does, the rebuild hides the bug.

## When the fix is about error reporting

A console screenshot doesn't show what the error tracker received. When the change filters or reports errors (Sentry `beforeSend`, a logger), build with a dummy DSN if the local one is empty. Intercept the tracker's requests with `context.route`, answer 200, and record the event items per case. Reproduce the reported entry path (the page and the load type from the issue), not a convenient neighbouring flow. Include a case where the fix can't help, to show real failures are still reported.

## Review

The console also shows dev-only noise, such as local debug loggers or framework dev tools. In each verdict, say which lines come from the change and which are local tooling.
