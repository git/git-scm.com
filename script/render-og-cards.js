#!/usr/bin/env node
// Generate a per-page Open Graph card (1200x630) for every Git manual page.
//
// To1ne's proposal (PR #2233): a clean, GitHub-style card that embeds the
// command name and its one-line tagline, so each docs page gets its own
// social preview instead of a single site-wide image. This implementation
// matches To1ne's reference SVG as closely as possible:
//   - warm off-white gradient background (#f0efe7 -> #f0f0f0)
//   - a 6px red top bar (Git brand color)
//   - the official Git logo (orange icon + dark "git" wordmark)
//   - the site tagline in grey
//   - a red "Latest: vX.Y.Z" pill top-right
//   - the hero title in serif, dark brown: "<command> - <one-line description>"
//   - a grey "git-scm.com" footer
// No hairline border, no divider line, no clutter (per dscho's review).
//
// Usage:
//   node script/render-og-cards.js [worktree-path] [--out <output-dir>]
//
// Reads each page under external/docs/content/docs/*.html, extracts the
// `docname` from frontmatter and the one-line NAME tagline from the body,
// and renders a card to static/images/og/<docname>.png (or <output-dir>/<docname>.png).
//
// Rendered with the repo's existing Playwright/Chromium stack (same as
// script/render-og-card.js), so no new language or toolchain is added.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Parse argv: optional worktree path and optional --out override.
const args = process.argv.slice(2);
let outArg = null;
let worktreeArg = '.';
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--out') { outArg = args[++i]; }
  else if (!args[i].startsWith('--')) { worktreeArg = args[i]; }
}
const WORKTREE = path.resolve(worktreeArg);
const DOCS_DIR = path.join(WORKTREE, 'external', 'docs', 'content', 'docs');
const OUT_DIR = outArg ? path.resolve(outArg) : path.join(WORKTREE, 'static', 'images', 'og');

// Official Git logo: the orange branch icon (from the official Git logo SVG).
const GIT_ICON = `<path id="icon" fill="#f03c2e" d="m 204.13634,307.32316 c -5.93629,5.9363 -15.56095,5.9363 -21.49726,0 L 79.452218,204.13631 c -5.93629,-5.93629 -5.93629,-15.56096 0,-21.49727 l 70.940982,-70.94095 26.96624,26.96624 c -2.40236,6.47829 -1.00079,14.04732 4.20479,19.25288 1.58036,1.58035 3.37855,2.81012 5.29789,3.68926 v 65.71214 c -1.91934,0.87916 -3.71753,2.10892 -5.29789,3.68927 -7.12357,7.12357 -7.12357,18.67317 0,25.79671 7.12357,7.12357 18.67313,7.12357 25.79671,0 7.12356,-7.12354 7.12356,-18.67314 0,-25.79671 -1.58036,-1.58035 -3.37856,-2.81011 -5.29793,-3.68927 v -63.95069 l 24.74015,24.74014 c -2.40235,6.4783 -1.00078,14.0473 4.20478,19.25286 7.12357,7.12358 18.67315,7.12358 25.79671,0 7.12356,-7.12357 7.12356,-18.67314 0,-25.79671 -5.20553,-5.20553 -12.77457,-6.60713 -19.25286,-4.20478 l -25.98605,-25.98606 c 2.40237,-6.47829 1.00076,-14.0473 -4.20478,-19.25285 -5.20553,-5.20553 -12.77458,-6.60715 -19.25286,-4.20479 l -26.96625,-26.96624 21.49726,-21.497264 c 5.93629,-5.936302 15.56096,-5.936302 21.49725,0 L 307.32321,182.63908 c 5.93631,5.93629 5.93631,15.56095 0,21.49726 z" style="stroke-width:3.04017"/>`;
// The dark "git" wordmark (from the official Git logo SVG).
const GIT_WORDMARK = `<path id="text" fill="#362701" d="m 380.12691,171.7981 c -7.8545,0 -13.708,3.86077 -13.708,13.14499 0,6.99436 3.85254,11.85478 13.2845,11.85478 7.99566,0 13.42732,-4.70613 13.42732,-12.14368 0,-8.42573 -4.86043,-12.85609 -13.00382,-12.85609 z m -15.70898,65.57719 c -1.85978,2.28167 -3.71303,4.71105 -3.71303,7.57052 0,5.71235 7.27833,7.42607 17.27988,7.42607 8.29113,0 19.57632,-0.57781 19.57632,-8.278 0,-4.58466 -5.43002,-4.867 -12.29141,-5.29706 z m 42.28621,-65.14713 c 2.56564,3.28954 5.28556,7.86107 5.28556,14.43356 0,15.85014 -12.42764,25.14093 -30.42649,25.14093 -4.5781,0 -8.71955,-0.57124 -11.29176,-1.28856 l -4.71104,7.57215 13.99527,0.85358 c 24.71907,1.57582 39.28722,2.29479 39.28722,21.28672 0,16.42795 -14.42698,25.71382 -39.28722,25.71382 -25.85333,0 -35.71372,-6.5725 -35.71372,-17.85932 0,-6.42968 2.85948,-9.8489 7.86105,-14.57308 -4.71925,-1.98783 -6.28359,-5.55969 -6.28359,-9.42046 0,-3.14179 1.56434,-6.00126 4.14146,-8.71955 2.57056,-2.71173 5.42511,-5.42509 8.85581,-8.56689 -6.996,-3.43071 -12.2865,-10.86169 -12.2865,-21.43448 0,-16.42794 10.85512,-27.7082 32.71473,-27.7082 6.14242,0 9.85546,0.56466 13.14499,1.43137 h 27.85922 v 12.13712 l -13.14334,1.00129 m 38.27278,-25.96331 c -8.14339,0 -12.85609,-4.71105 -12.85609,-12.86264 0,-8.13683 4.7127,-12.56719 12.85609,-12.56719 8.2895,0 13.00383,4.432 13.00383,12.56719 0,8.14994 -4.7127,12.86264 -13.00383,12.86264 z m -18.42891,85.85771 v -11.28684 l 7.28488,-0.99473 c 2.00099,-0.28726 2.28824,-0.71733 2.28824,-2.86603 v -41.99731 c 0,-1.56433 -0.42843,-2.57055 -1.85816,-2.99405 l -7.71496,-2.7183 1.5709,-11.56752 h 29.57294 v 59.28046 c 0,2.29644 0.14116,2.57713 2.28985,2.86602 l 7.28325,0.99475 v 11.28519 h -40.71694 m 97.20691,-5.54329 c -6.14244,2.9957 -15.13939,5.714 -23.28771,5.714 -16.99918,0 -23.42394,-6.85319 -23.42394,-23.00537 v -37.42086 c 0,-0.86012 0,-1.42972 -1.14904,-1.42972 h -10.00154 v -12.71492 c 12.58031,-1.42973 17.57534,-7.71989 19.14624,-23.28934 h 13.57504 v 20.28872 c 0,0.99966 0,1.42809 1.14084,1.42809 h 20.14098 v 14.28745 h -21.28182 v 34.13789 c 0,8.43065 1.99933,11.71361 9.7143,11.71361 4.00029,0 8.14175,-0.99965 11.56752,-2.28166 l 3.85913,12.57376" style="stroke-width:1.64148"/>`;

function currentVersion() {
  const hugo = fs.readFileSync(path.join(WORKTREE, 'hugo.yml'), 'utf8');
  const m = hugo.match(/^\s*latest_version:\s*([0-9][^\s]*)/m);
  if (!m) throw new Error('Could not find latest_version in hugo.yml');
  return m[1];
}

// Escape XML special characters for embedding in SVG text.
function esc(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

// Decode common HTML entities that appear in manual page bodies.
function decodeEntities(s) {
  const map = {
    '&#8217;': "'", '&#8216;': "'", '&#8220;': '"', '&#8221;': '"',
    '&#8212;': '\u2014', '&#8203;': '', '&amp;': '&', '&lt;': '<',
    '&gt;': '>', '&quot;': '"', '&apos;': "'", '&#39;': "'",
    '&#8230;': '\u2026', '&nbsp;': ' ',
  };
  let out = s;
  for (const [k, v] of Object.entries(map)) out = out.split(k).join(v);
  return out;
}

// Extract the one-line NAME tagline from a manual page body.
// The NAME section looks like:
//   <h2 id="_name">...NAME</h2>
//   <div class="sectionbody"><div class="paragraph"><p>git-clone - Clone a repository into a new directory</p>
function extractTagline(html) {
  const m = html.match(
    /<h2 id="_name"[^>]*>.*?<\/h2>\s*<div class="sectionbody">\s*<div class="paragraph">\s*<p>(.*?)<\/p>/s
  );
  if (!m) return null;
  return decodeEntities(m[1].replace(/<[^>]+>/g, '')).trim();
}

// Extract the `docname:` value from a page's YAML frontmatter.
function extractDocname(html) {
  const m = html.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!m) return null;
  const fm = m[1].match(/^docname:\s*(.+)$/m);
  return fm ? decodeEntities(fm[1].trim()) : null;
}

// Wrap a text line into at most `maxLines` lines that each fit within
// `maxChars` characters (average glyph width ~0.52em). Returns an array.
function wrap(text, maxChars) {
  if (!text) return [];
  const words = text.split(/\s+/);
  const lines = [];
  let cur = '';
  for (const w of words) {
    const probe = cur ? cur + ' ' + w : w;
    if (probe.length > maxChars && cur) {
      lines.push(cur);
      cur = w;
    } else {
      cur = probe;
    }
  }
  if (cur) lines.push(cur);
  return lines;
}

// Build the SVG card, matching To1ne's reference design as closely as possible.
//   - warm off-white gradient background
//   - a 6px red top bar
//   - official Git logo (orange icon + dark "git" wordmark) top-left
//   - the site tagline in grey below the logo
//   - a red "Latest: vX.Y.Z" pill top-right
//   - the hero title in serif, dark brown: "<command> - <description>"
//   - a grey "git-scm.com" footer
function cardSvg({ docname, tagline, version }) {
  const title = tagline || docname;
  const dash = title.indexOf(' - ');
  const command = dash >= 0 ? title.slice(0, dash) : title;
  const desc = dash >= 0 ? title.slice(dash + 3) : '';

  // The hero title is "<command> - <description>" in serif. Long descriptions
  // wrap to a second line; the command name auto-shrinks for very long names.
  const AVAIL = 900;
  let fontSize = 42;
  let lines = wrap(title, Math.floor(AVAIL / (fontSize * 0.5)));
  while (fontSize > 28 && lines.length > 2) {
    fontSize -= 2;
    lines = wrap(title, Math.floor(AVAIL / (fontSize * 0.5)));
  }
  lines = lines.slice(0, 2); // never overflow the card
  const lineHeight = fontSize * 1.3;
  const titleLines = lines.map((ln, i) =>
    `<tspan x="116" dy="${i === 0 ? 0 : lineHeight}">${esc(ln)}</tspan>`
  ).join('');

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#f0efe7"/>
      <stop offset="1" stop-color="#f0f0f0"/>
    </linearGradient>
  </defs>
  <rect width="1200" height="630" fill="url(#bg)"/>
  <!-- red top bar -->
  <rect x="0" y="0" width="1200" height="6" fill="#f03c2e"/>

  <!-- Official Git logo: orange icon + dark "git" wordmark -->
  <g transform="translate(116 120) scale(0.42)">
    ${GIT_ICON}
    ${GIT_WORDMARK}
  </g>

  <!-- Site tagline -->
  <text x="116" y="330" font-family="Helvetica, Arial, sans-serif" font-size="30" fill="#555555">Free and open source distributed version control system</text>

  <!-- Version pill -->
  <g transform="translate(0,-18.355016)">
    <rect x="764" y="180" width="300" height="64" rx="32" fill="#f03c2e"/>
    <text x="914" y="222" font-family="Helvetica, Arial, sans-serif" font-size="30" font-weight="bold" fill="#ffffff" text-anchor="middle">Latest: v${esc(version)}</text>
  </g>

  <!-- Hero title: "<command> - <description>" in serif, dark brown -->
  <text x="116" y="452" font-family="Georgia, 'Times New Roman', serif" font-size="${fontSize}" fill="#4e443c">${titleLines}</text>

  <!-- Footer: URL -->
  <text x="116" y="550" font-family="Helvetica, Arial, sans-serif" font-size="26" fill="#888888">git-scm.com</text>
</svg>`;
}

(async () => {
  const version = currentVersion();
  if (!fs.existsSync(DOCS_DIR)) {
    console.error(`Docs dir not found: ${DOCS_DIR}`);
    process.exit(1);
  }
  const files = fs.readdirSync(DOCS_DIR).filter((f) => f.endsWith('.html'));
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });

  let rendered = 0;
  let skipped = 0;
  for (const file of files) {
    const html = fs.readFileSync(path.join(DOCS_DIR, file), 'utf8');
    const docname = extractDocname(html);
    const tagline = extractTagline(html);
    if (!docname || !tagline) {
      skipped++;
      continue;
    }
    const svg = cardSvg({ docname, tagline, version });
    const svgPath = path.join(OUT_DIR, `${docname}.svg`);
    const pngPath = path.join(OUT_DIR, `${docname}.png`);
    fs.writeFileSync(svgPath, svg);
    await page.goto('file://' + svgPath);
    await page.waitForTimeout(120);
    await page.screenshot({ path: pngPath, clip: { x: 0, y: 0, width: 1200, height: 630 } });
    fs.unlinkSync(svgPath); // keep only the PNG
    rendered++;
  }
  await browser.close();
  console.log(`Rendered ${rendered} per-page OG cards to ${OUT_DIR} (skipped ${skipped} pages without a NAME tagline). Git ${version}`);
})().catch((e) => { console.error(e); process.exit(1); });
