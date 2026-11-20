// Adds a Chrome-like address bar above a headless flow video, which records the page only.
// The bar shows the URL the page was on at each moment, read from the <video>-navs.json log the flow wrote:
// e.g. [{ "t": 0.4, "url": "http://localhost:8000/invoices" }, { "t": 6.2, "url": "http://localhost:8000/invoices/7" }],
// t in seconds from the start of the recording.
//
// When the flow also wrote <video>-notes.json, the bar draws what the page can't show:
//   { "t": 3.1, "account": "Profile B", "role": "admin" }  a chip at the right of the bar naming the account on screen,
//                                                          kept until the next account entry
//   { "t": 3.2, "title": "Switched to Profile B", "detail": "An admin revokes access", "seconds": 2.8 }
//                                                          a message that slides out from under the bar, then back
//
// Run it from a repo that has @playwright/test or playwright installed; it renders the bar with that Chromium.
//   node ~/.claude/skills/custom-user-flow-capture/assets/address-bar.mjs <flow.webm> <output.webm> [lead-seconds]
// GitHub shows the uploaded file name as the video title, so name <output.webm> after the flow it shows.
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { join } from "node:path";

const [videoPath, outputPath, leadArg] = process.argv.slice(2);
if (!videoPath || !outputPath) {
  console.error("usage: address-bar.mjs <flow.webm> <output.webm> [lead-seconds]");
  process.exit(5);
}
const base = videoPath.replace(/\.webm$/, "");
const barHeight = 52;
// a URL is logged after the new page shows, but a browser changes its bar as the page starts loading
const lead = Number(leadArg ?? 0.5);

// Step 1: probe the video and turn the URL log into [start, end) segments, one per URL.
const probe = (entries) =>
  execFileSync("ffprobe", ["-v", "error", "-select_streams", "v:0", "-show_entries", entries, "-of", "csv=p=0", videoPath])
    .toString()
    .trim();
const width = Number(probe("stream=width"));
const duration = Number(probe("format=duration"));
const navs = JSON.parse(readFileSync(`${base}-navs.json`, "utf8"))
  .filter((nav) => nav.url !== "about:blank")
  .map((nav) => ({ ...nav, t: Math.max(0, nav.t - lead) }));
const segments = navs
  .filter((nav, i) => i === 0 || nav.url !== navs[i - 1].url)
  .map((nav, i, all) => ({ url: nav.url, start: nav.t, end: all[i + 1]?.t ?? duration }));
const notesPath = `${base}-notes.json`;
const notes = existsSync(notesPath) ? JSON.parse(readFileSync(notesPath, "utf8")) : [];
const accounts = notes.filter((note) => note.account);
const accountNames = [...new Set(accounts.map((note) => note.account))];
// a message ends early when the next one starts, so two never overlap
const messages = notes
  .filter((note) => note.title)
  .map((note, i, all) => ({ ...note, start: note.t, end: Math.min(note.t + (note.seconds ?? 2.8), all[i + 1]?.t ?? duration) }));
// the bar changes whenever the URL or the account does
const latestBefore = (entries, time) => entries.findLast((entry) => (entry.start ?? entry.t) <= time);
const barStarts = [...new Set([0, ...segments.map((segment) => segment.start), ...accounts.map((note) => note.t)])].sort((a, b) => a - b);
const bars = barStarts.map((start, i) => ({
  start,
  end: barStarts[i + 1] ?? duration,
  url: latestBefore(segments, start)?.url ?? "",
  account: latestBefore(accounts, start),
}));

// Step 2: render one bar per URL and account on screen, and one image per message.
const requireFromRepo = createRequire(join(process.cwd(), "noop.js"));
const { chromium } = (() => {
  for (const name of ["@playwright/test", "playwright"]) {
    try {
      return requireFromRepo(name);
    } catch {}
  }
  console.error("run this from a repo with @playwright/test or playwright installed");
  process.exit(1);
})();

const icon = (d, size = 20) =>
  `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="#5f6368" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;
const escapeHtml = (text) => text.replace(/&/g, "&amp;").replace(/</g, "&lt;");
const chipColors = ["#4f46e5", "#d9730d", "#0f8a5f", "#c2255c"];
const chipHtml = (account) => `<div style="height:34px;border-radius:17px;padding:0 14px 0 10px;display:flex;align-items:center;gap:8px;
    white-space:nowrap;font-size:14px;font-weight:600;color:#fff;background:${chipColors[accountNames.indexOf(account.account) % chipColors.length]}">
    <svg width="16" height="16" viewBox="0 0 24 24" fill="#fff"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0z"/></svg>
    <span>${escapeHtml(account.account)}${account.role ? ` <span style="font-weight:400;opacity:.85">(${escapeHtml(account.role)})</span>` : ""}</span>
  </div>`;
const barHtml = ({ url, account }) => `<!doctype html><html><body style="margin:0">
<div style="box-sizing:border-box;width:${width}px;height:${barHeight}px;display:flex;align-items:center;gap:14px;padding:0 14px;
  background:#f8f9fa;border-bottom:1px solid #dadce0;font-family:-apple-system,BlinkMacSystemFont,sans-serif">
  ${icon('<path d="M19 12H5M12 19l-7-7 7-7"/>')}
  ${icon('<path d="M5 12h14M12 5l7 7-7 7"/>')}
  ${icon('<path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/>')}
  <div style="flex:1;min-width:0;height:34px;border-radius:17px;background:#edf0f2;display:flex;align-items:center;gap:10px;padding:0 14px">
    ${url ? icon('<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>', 16) : ""}
    <span style="font-size:15px;color:#1f1f1f;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${escapeHtml(url.replace(/^https?:\/\//, ""))}</span>
  </div>
  ${account ? chipHtml(account) : ""}
</div></body></html>`;
// the 30px of transparent padding keeps the shadow in the image
const messageHtml = (message) => `<!doctype html><html><body style="margin:0;background:transparent">
<div id="message" style="display:inline-block;padding:0 30px 30px">
  <div style="box-sizing:border-box;min-width:400px;max-width:${Math.round(width * 0.6)}px;padding:12px 34px 15px;border-radius:0 0 20px 20px;
    background:rgba(0,0,0,.78);color:#fff;text-align:center;box-shadow:0 10px 28px rgba(0,0,0,.22);font-family:-apple-system,BlinkMacSystemFont,sans-serif">
    <div style="font-size:19px;font-weight:600">${escapeHtml(message.title)}</div>
    ${message.detail ? `<div style="font-size:14px;opacity:.75;margin-top:2px">${escapeHtml(message.detail)}</div>` : ""}
  </div>
</div></body></html>`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width, height: 400 } });
for (const [i, bar] of bars.entries()) {
  await page.setContent(barHtml(bar));
  await page.screenshot({ path: `${base}-bar${i}.png`, clip: { x: 0, y: 0, width, height: barHeight } });
}
for (const [i, message] of messages.entries()) {
  await page.setContent(messageHtml(message));
  await page.locator("#message").screenshot({ path: `${base}-message${i}.png`, omitBackground: true });
}
await browser.close();

// Step 3: pad the video at the top, slide each message out from under the bar, and overlay each bar during its segment.
// Messages go on first, so the bar covers the part of a message that hasn't slid out yet.
// 0 → 1 easing out as a message starts, then 1 → 0 easing in as it ends
const slideOut = (message) => {
  // a message cut short by the next one still slides fully out before it slides back
  const slideSeconds = Math.min(0.45, (message.end - message.start) / 2).toFixed(3);

  return `(1-pow(1-clip((t-${message.start.toFixed(3)})/${slideSeconds},0,1),3))*(1-pow(clip((t-${message.end.toFixed(3)})/${slideSeconds}+1,0,1),3))`;
};
const overlays = messages
  .map(
    (message, i) =>
      `[${i + 1}:v]overlay=(W-w)/2:'${barHeight}-h+h*${slideOut(message)}':enable='between(t,${message.start.toFixed(3)},${message.end.toFixed(3)})'`,
  )
  .concat(
    bars.map(
      (bar, i) => `[${messages.length + i + 1}:v]overlay=0:0:enable='between(t,${bar.start.toFixed(3)},${bar.end.toFixed(3)})'`,
    ),
  );
const filter = [`[0:v]pad=${width}:ih+${barHeight}:0:${barHeight}:color=white[v0]`]
  .concat(overlays.map((overlay, i) => `[v${i}]${overlay}[v${i + 1}]`))
  .join(";");
execFileSync("ffmpeg", [
  "-y", "-v", "error",
  "-i", videoPath,
  ...messages.flatMap((_, i) => ["-loop", "1", "-i", `${base}-message${i}.png`]),
  ...bars.flatMap((_, i) => ["-loop", "1", "-i", `${base}-bar${i}.png`]),
  "-filter_complex", filter,
  "-map", `[v${overlays.length}]`,
  "-t", String(duration),
  "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "32", "-row-mt", "1", "-deadline", "good", "-cpu-used", "4",
  outputPath,
]);

console.log("--------- Result ---------");
console.log(outputPath);
segments.forEach((segment) => console.log(`${segment.start.toFixed(1)}s ${segment.url}`));
