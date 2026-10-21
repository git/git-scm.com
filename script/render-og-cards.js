#!/usr/bin/env node
// Generate a per-page Open Graph card (1200x630) for every Git manual page.
//
// To1ne's proposal (PR #2233): a clean, GitHub-style card that embeds the
// command name and its one-line tagline, so each docs page gets its own
// social preview instead of a single site-wide image. The layout mirrors his
// reference: site branding at the top (logo + version pill + site tagline)
// and the command name + description as the hero below, with tasteful
// structuring elements (a hairline border, a red top bar, generous margins)
// per dscho's review of the earlier draft.
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

// Official Git logo (orange icon) as a reusable SVG fragment.
const GIT_ICON = `<path fill="#f03c2e" transform="scale(1.179487) translate(10 10) rotate(-45 29 29)" d="M5,58c-2.76142,0 -5,-2.23858 -5,-5v-48c0,-2.76142 2.23858,-5 5,-5h33v12.54404c-2.06553,0.94801 -3.5,3.03446 -3.5,5.45596c0,0.73514 0.13221,1.43941 0.37415,2.09031l-15.28384,15.28384c-0.6509,-0.24194 -1.35517,-0.37415 -2.09031,-0.37415c-3.31371,0 -6,2.68629 -6,6c0,3.31371 2.68629,6 6,6c3.31371,0 6,-2.68629 6,-6c0,-0.73514 -0.13221,-1.43941 -0.37415,-2.09031l14.87415,-14.87415l0,11.50851c-2.06553,0.94801 -3.5,3.03446 -3.5,5.45596c0,3.31371 2.68629,6 6,6c3.31371,0 6,-2.68629 6,-6c0,-2.42149 -1.43447,-4.50795 -3.5,-5.45596l0,-12.08808c2.06553,-0.94801 3.5,-3.03446 3.5,-5.45596c0,-2.42149 -1.43447,-4.50795 -3.5,-5.45596l0,-12.54404h10c2.76142,0 5,2.23858 5,5v48c0,2.76142 -2.23858,5 -5,5z"/>`;

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

// Build the SVG card. The layout follows To1ne's proposal:
//   - a 6px red top bar (Git brand color)
//   - a hairline border for structure (dscho: "tasteful structuring elements")
//   - top: logo + "git" wordmark, and a red "Latest: vX.Y.Z" pill
//   - below the brand row: the site tagline in grey
//   - the hero: command name (bold) + one-line description (auto-wrapped)
//   - footer: git-scm.com/docs/<docname>
function cardSvg({ docname, tagline, version }) {
  const title = tagline || docname;
  const dash = title.indexOf(' - ');
  const command = dash >= 0 ? title.slice(0, dash) : title;
  const desc = dash >= 0 ? title.slice(dash + 3) : '';

  // Description must fit in ~920px (120px left margin + 160px right zone).
  const AVAIL = 920;
  let fontSize = 30;
  let lines = wrap(desc, Math.floor(AVAIL / (fontSize * 0.52)));
  while (fontSize > 20 && lines.length > 2) {
    fontSize -= 2;
    lines = wrap(desc, Math.floor(AVAIL / (fontSize * 0.52)));
  }
  lines = lines.slice(0, 2); // never overflow the card
  const lineHeight = fontSize * 1.28;
  const descLines = lines.map((ln, i) =>
    `<tspan x="120" dy="${i === 0 ? 0 : lineHeight}">${esc(ln)}</tspan>`
  ).join('');

  // Command name hero: shrink for very long names.
  const cmdSize = command.length > 26 ? 56 : 68;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#fbfaf7"/>
      <stop offset="1" stop-color="#f2f1ec"/>
    </linearGradient>
  </defs>
  <rect width="1200" height="630" fill="url(#bg)"/>
  <!-- hairline border for structure -->
  <rect x="1" y="1" width="1198" height="628" fill="none" stroke="#e2e0d8" stroke-width="2"/>
  <!-- red top bar -->
  <rect x="0" y="0" width="1200" height="6" fill="#f03c2e"/>

  <!-- Brand row: logo + wordmark + version pill -->
  <g transform="translate(120 96) scale(1.9)">
    ${GIT_ICON}
  </g>
  <text x="196" y="196" font-family="Helvetica, Arial, sans-serif" font-size="58" font-weight="bold" fill="#362701">git</text>
  <g transform="translate(900 120)">
    <rect x="0" y="0" width="290" height="64" rx="32" fill="#f03c2e"/>
    <text x="145" y="42" font-family="Helvetica, Arial, sans-serif" font-size="30" font-weight="bold" fill="#ffffff" text-anchor="middle">Latest: v${esc(version)}</text>
  </g>

  <!-- Site tagline -->
  <text x="120" y="262" font-family="Helvetica, Arial, sans-serif" font-size="26" fill="#8a8a8a">Free and open source distributed version control system</text>

  <!-- divider -->
  <line x1="120" y1="292" x2="1080" y2="292" stroke="#e2e0d8" stroke-width="1"/>

  <!-- Hero: command name + description -->
  <text x="120" y="368" font-family="Helvetica, Arial, sans-serif" font-size="${cmdSize}" font-weight="bold" fill="#362701">${esc(command)}</text>
  <text x="120" y="432" font-family="Helvetica, Arial, sans-serif" font-size="${fontSize}" fill="#555555">${descLines}</text>

  <!-- Footer: URL -->
  <text x="120" y="575" font-family="Helvetica, Arial, sans-serif" font-size="24" fill="#8a8a8a">git-scm.com/docs/${esc(docname)}</text>
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
