// Adds a Chrome-like address bar above a headless flow video, which records the page only.
// The bar shows the URL the page was on at each moment, read from the <video>-navs.json log the flow wrote:
// e.g. [{ "t": 0.4, "url": "http://localhost:8000/invoices" }, { "t": 6.2, "url": "http://localhost:8000/invoices/7" }],
// t in seconds from the start of the recording.
//
// Run it from a repo that has @playwright/test or playwright installed; it renders the bar with that Chromium.
//   node ~/.claude/skills/custom-user-flow-capture/assets/address-bar.mjs <flow.webm> [lead-seconds]
// It writes <flow>-chrome.webm next to the video.
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { join } from "node:path";

const [videoPath, leadArg] = process.argv.slice(2);
if (!videoPath) {
  console.error("usage: address-bar.mjs <flow.webm> [lead-seconds]");
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

// Step 2: render the empty bar, then one bar per segment.
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
const barHtml = (url) => `<!doctype html><html><body style="margin:0">
<div style="box-sizing:border-box;width:${width}px;height:${barHeight}px;display:flex;align-items:center;gap:14px;padding:0 14px;
  background:#f8f9fa;border-bottom:1px solid #dadce0;font-family:-apple-system,BlinkMacSystemFont,sans-serif">
  ${icon('<path d="M19 12H5M12 19l-7-7 7-7"/>')}
  ${icon('<path d="M5 12h14M12 5l7 7-7 7"/>')}
  ${icon('<path d="M21 12a9 9 0 1 1-3-6.7L21 8"/><path d="M21 3v5h-5"/>')}
  <div style="flex:1;min-width:0;height:34px;border-radius:17px;background:#edf0f2;display:flex;align-items:center;gap:10px;padding:0 14px">
    ${url ? icon('<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>', 16) : ""}
    <span style="font-size:15px;color:#1f1f1f;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${escapeHtml(url.replace(/^https?:\/\//, ""))}</span>
  </div>
</div></body></html>`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width, height: barHeight } });
const bars = [{ url: "", start: 0, end: segments[0]?.start ?? duration }].concat(segments);
for (const [i, bar] of bars.entries()) {
  await page.setContent(barHtml(bar.url));
  await page.screenshot({ path: `${base}-bar${i}.png` });
}
await browser.close();

// Step 3: pad the video at the top and overlay each bar during its segment.
const filter = [`[0:v]pad=${width}:ih+${barHeight}:0:${barHeight}:color=white[v0]`]
  .concat(
    bars.map(
      (bar, i) => `[v${i}][${i + 1}:v]overlay=0:0:enable='between(t,${bar.start.toFixed(3)},${bar.end.toFixed(3)})'[v${i + 1}]`,
    ),
  )
  .join(";");
execFileSync("ffmpeg", [
  "-y", "-v", "error",
  "-i", videoPath,
  ...bars.flatMap((_, i) => ["-loop", "1", "-i", `${base}-bar${i}.png`]),
  "-filter_complex", filter,
  "-map", `[v${bars.length}]`,
  "-t", String(duration),
  "-c:v", "libvpx-vp9", "-b:v", "0", "-crf", "32", "-row-mt", "1", "-deadline", "good", "-cpu-used", "4",
  `${base}-chrome.webm`,
]);

console.log("--------- Result ---------");
console.log(`${base}-chrome.webm`);
segments.forEach((segment) => console.log(`${segment.start.toFixed(1)}s ${segment.url}`));
