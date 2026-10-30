// Records a user flow as a WebM with Playwright, drawing cursor.js's arrow and logging each URL for address-bar.mjs.
// A repo script imports it by absolute path and keeps only its own steps:
//
//   import { homedir } from "node:os";
//   const { startFlow } = await import(`${homedir()}/.claude/skills/custom-user-flow-capture/assets/playwright-flow.mjs`);
//   const flow = await startFlow({
//     out: "<scratchpad>/flow-<name>/after",
//     login: async (page) => { await page.goto(".../login"); ... },
//   });
//   await flow.page.goto(".../invoices");
//   await flow.clickOn(flow.page.getByRole("button", { name: "Download" }));
//   await flow.finish();   // writes <out>/flow.webm and <out>/flow-navs.json
//
// Run it from the repo root: Playwright resolves from the working directory, so the skill needs no node_modules.
import { readFileSync, renameSync, statSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { join } from "node:path";

const cursorScript = readFileSync(new URL("./cursor.js", import.meta.url), "utf8");

const loadChromium = () => {
  const require = createRequire(join(process.cwd(), "package.json"));
  for (const name of ["@playwright/test", "playwright"]) {
    try {
      return require(name).chromium;
    } catch {}
  }
  throw new Error("Run from a repo that has @playwright/test or playwright installed.");
};

/**
 * Logs in outside the recording, then opens a recorded page with the drawn cursor.
 * @param {{ out: string, login?: (page) => Promise<void>, viewport?: { width: number, height: number } }} options
 */
export const startFlow = async ({ out, login, viewport = { width: 1440, height: 900 } }) => {
  const browser = await loadChromium().launch();

  // Step 1: login, not recorded, so the video starts at the flow and shows no credentials.
  let storageState;
  if (login) {
    const loginContext = await browser.newContext({ ignoreHTTPSErrors: true, viewport });
    await login(await loginContext.newPage());
    storageState = await loginContext.storageState();
    await loginContext.close();
  }

  // Step 2: the recorded context. The cursor goes in as an init script, so every new document gets it.
  const context = await browser.newContext({
    ignoreHTTPSErrors: true,
    viewport,
    storageState,
    recordVideo: { dir: out, size: viewport },
  });
  await context.addInitScript({ content: cursorScript });
  const page = await context.newPage();

  // Logs each top-frame URL with its time from the recording start, for address-bar.mjs.
  const startedAt = Date.now();
  const navs = [];
  page.on("framenavigated", (frame) => {
    if (frame !== page.mainFrame()) return;
    navs.push({ t: (Date.now() - startedAt) / 1000, url: frame.url() });
  });

  // A failed step leaves a screenshot of where it stopped instead of only a stack trace.
  process.on("unhandledRejection", async (error) => {
    console.error("failed at", page.url(), String(error?.message ?? error).split("\n")[0]);
    await page.screenshot({ path: join(out, "flow-failed.png") }).catch(() => {});
    process.exit(1);
  });

  const waitForCursor = () => page.waitForFunction(() => performance.now() >= (window.__flowCursorBusyUntil ?? 0));

  // Glides the arrow to (x, y), then lands the real pointer on it, so hover starts when the arrow arrives.
  const moveTo = async (x, y) => {
    await page.evaluate(([x, y]) => window.__flowCursorGlideTo(x, y), [x, y]);
    await waitForCursor();
    await page.mouse.move(x, y);
  };

  // A random point in the middle of <locator>, so repeated runs don't land on the same pixel.
  const pointIn = async (locator) => {
    const box = await locator.boundingBox();
    if (!box) throw new Error(`no box for ${locator}`);

    return [
      Math.round(box.x + box.width * (0.35 + Math.random() * 0.3)),
      Math.round(box.y + box.height * (0.4 + Math.random() * 0.2)),
    ];
  };

  // Glides to <locator> and clicks it with real mouse events, so the ripple shows where it lands.
  const clickOn = async (locator) => {
    await locator.waitFor();
    await moveTo(...(await pointIn(locator)));
    await page.mouse.down();
    await page.mouse.up();
  };

  // Points the viewer at <locator>: glides to its left edge, then loops twice, fast, around it ("look here").
  const lookAt = async (locator) => {
    await locator.waitFor();
    const box = await locator.boundingBox();
    await moveTo(Math.round(box.x - 8), Math.round(box.y + box.height / 2));
    await page.evaluate(
      ([rx, ry]) => window.__flowCursorCircle(rx, ry),
      [Math.round(box.width / 2) + 8, Math.round(box.height / 2) + 10],
    );
    await waitForCursor();
  };

  // Shows the back badge before a browser back, which the video would otherwise show as an unexplained jump.
  const goBack = async () => {
    await page.evaluate(() => window.__flowCursorBack());
    await page.goBack();
  };

  // Clicks <locator>, waits for the file, and shows the download bubble with its real name and size.
  // Catches the download on any page, since apps often stream a file through a new tab.
  const download = async (locator) => {
    const downloaded = new Promise((resolve) => {
      page.on("download", resolve);
      context.on("page", (tab) => tab.on("download", resolve));
    });
    await clickOn(locator);
    const file = await downloaded;
    const kb = statSync(await file.path()).size / 1024;
    await page.bringToFront();
    await page.evaluate(
      ([name, size]) => window.__flowCursorDownloaded(name, size),
      [file.suggestedFilename(), kb < 1024 ? `${kb.toFixed(1)} KB` : `${(kb / 1024).toFixed(1)} MB`],
    );

    return file;
  };

  // Closes the context, which writes the video, then names it flow.webm next to flow-navs.json.
  const finish = async (name = "flow") => {
    const video = page.video();
    await context.close();
    const path = join(out, `${name}.webm`);
    renameSync(await video.path(), path);
    writeFileSync(join(out, `${name}-navs.json`), JSON.stringify(navs));
    await browser.close();

    return path;
  };

  return { browser, context, page, moveTo, clickOn, lookAt, goBack, download, finish };
};
