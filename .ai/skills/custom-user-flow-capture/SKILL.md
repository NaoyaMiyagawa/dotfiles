---
name: custom-user-flow-capture
description: Capture a user flow as numbered step screenshots with ego-browser, or as a screen recording video with headless agent-browser, then review them, to show how the UI looks after a feature or bug fix. Covers backend changes as well as frontend ones. Use when a change alters what a user sees or does in a flow (new page or step, changed validation, new error or empty state, different data shown), when the user asks for flow screenshots, a before/after comparison, visual evidence for a PR, a video, screen recording, or QA recording of a flow, including screenshots that show the DevTools console.
---

# User Flow Capture

Walk the changed flow in the real app like a user would, save one screenshot per step, then look at every image. The screenshots are the evidence that the change works. A passing test suite does not replace them.

When the user wants a video, or the point is the navigation between pages rather than how one screen looks, record it instead. Follow steps 1, 2, 4 and 5 below, and replace step 3 with [references/video.md](references/video.md).

## Workflow

1. **Script the flow from the diff.** Read the change and trace it to what the user sees: the routes, pages, and states it touches. A backend change shows up through the screens that render its data, validation, or errors. List the steps as entry URL, then action, then expected visible result. Include the edge state the change is about (the error message, the empty list, the new status badge), not only the happy path. Done when every user-visible effect of the diff maps to at least one step.
2. **Prepare state.** Start the app and anything it needs (dev server, database, queue worker). Seed the records the flow needs with the project's own tools (factories, seeders, tinker). Don't click through setup screens that aren't part of the change. If the flow needs a login you don't have, or data you can't create, ask the user.
3. **Capture.** Load the `ego-browser` skill first. It has the API. Write the script to the scratchpad as `flow.mjs` and run it with `ego-browser nodejs < flow.mjs` so it can run again unchanged. In one run, do each step, wait for its expected state (`waitForSelector`, `waitForURL`, `waitForFunction`, never a fixed delay), and screenshot to `<scratchpad>/flow-<name>/<side>/NN-<step>.png`. Use absolute paths, because the script runs with `/` as its working directory. Keep the viewport the same across runs. Call `task.finish({ keep: [] })` at the end. When the evidence is in the browser console rather than the page (an uncaught error, a failed module import), read [references/devtools-console.md](references/devtools-console.md) first: ego-browser screenshots never include DevTools.
4. **Before/after, when the change alters an existing screen or fixes a bug.** Run the same script against the base branch into `before/`, and against the change into `after/`. Switch branches only with a clean working tree. Otherwise capture `before/` first, before editing. Rebuild or restart the app after switching if it doesn't hot-reload.
5. **Review every image.** Open each PNG with Read. Check the expected result is visible and nothing else broke. For a bug fix, the `before/` images must show the symptom the report names (the console error, the failed request), not only a UI effect downstream of it. Also check for error toasts, stack traces, overflow, missing data, broken layout. A step that shows something unexpected is a defect to fix or report. Don't hide it by skipping the screenshot. Done when every image has a one-line verdict.

## Output

Give a table: step, screenshot path, verdict (and the matching before path when you captured one). Put defects first. If the user wants the images or video in a PR, give the paths. Attaching them is up to the user.

## Rules

- Don't capture real customer data or secrets. Use seeded data, and say so if a screen shows anything sensitive.
- Keep the script flow-only. Don't add checks the test suite already covers. The screenshots are for looking at.
- If ego-browser can't reach the app (auth wall, browser prompt, device chooser), hand off with `task.handOff()` and tell the user what to do. Don't route around it.
