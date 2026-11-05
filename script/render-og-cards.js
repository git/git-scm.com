#!/usr/bin/env node
// Generate a per-page Open Graph card (1200x630) for every Git manual page.
//
// Design source: the maintainers' own SVG (To1ne's proposal, posted by dscho
// on PR #2233) — script/og-card-design.svg. This script loads that exact
// file as the canonical design and substitutes only the per-page text:
//   - the hero title (tspan #tspan4): "<command> - <one-line description>"
//   - the version pill (tspan #tspan6): "Latest: vX.Y.Z"
// Everything else — logo, colors, fonts, sizes, transforms — comes verbatim
// from the maintainers' file, so the rendered card matches their reference
// pixel-for-pixel (fonts: Arial for tagline/pill/footer, Times New Roman for
// the hero title; background #f0efea; 6px red top bar #f03c2e).
//
// Long titles: the reference is a single line. For titles wider than the card
// (e.g. git-fsck-objects, 88 chars), the hero text auto-sizes to a slightly
// smaller size on the same baseline (never wraps, never overlaps) so it stays
// readable and inside the canvas.
//
// Usage:
//   node script/render-og-cards.js [worktree-path] [--out <output-dir>]
//
// Reads each page under external/docs/content/docs/*.html, extracts the
// `docname` from frontmatter and the one-line NAME tagline from the body,
// and renders a card to static/images/og/<docname>.png (or <output-dir>/<docname>.png).
//
// Rendered with the repo's existing Playwright/Chromium stack.
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
const DESIGN = fs.readFileSync(path.join(WORKTREE, 'script', 'og-card-design.svg'), 'utf8');

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
//   <h2 id="_name">NAME</h2>
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

// Substitute the per-page hero title into the maintainers' design SVG.
// The hero tspan (#tspan4) is a single line at the reference size (32px in
// the source transform). For titles wider than the available canvas the
// renderer measures the real on-screen width and reduces the tspan font-size
// until the line fits inside the card (never wraps, never overlaps). The
// reference title "git-clone - Clone a repository into a new directory"
// renders at 32px untouched.
function cardSvg({ title, version, fontSize }) {
  const TITLE = esc(title);
  const PILL = `Latest: v${esc(version)}`;
  // The design SVG carries all-upper-case PLACEHOLDERS for the variable
  // values (hero title, hero font-size, version pill). Replace them verbatim
  // — no regex. Everything else stays verbatim from the maintainers' file.
  return DESIGN
    .replace('__HERO_TITLE__', TITLE)
    .replace('__HERO_FONT_SIZE__', String(fontSize))
    .replace('__VERSION__', version);
}

// Measure the rendered hero text's right edge (in screen px). The hero tspan
// lives under a matrix transform; getCTM() already resolves the full chain
// (tspan -> text -> ... -> svg -> viewport), so the transformed point is
// already in screen pixels — do NOT re-scale by viewBox.
async function heroRightEdge(page, svgPath) {
  await page.goto('file://' + svgPath);
  await page.waitForTimeout(120);
  return page.evaluate(() => {
    const tsp = document.getElementById('tspan4');
    if (!tsp) return null;
    const b = tsp.getBBox();
    const ctm = tsp.getCTM();
    const p = new DOMPoint(b.x + b.width, b.y).matrixTransform(ctm);
    return p.x;
  });
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
  let shrunk = 0;
  for (const file of files) {
    const html = fs.readFileSync(path.join(DOCS_DIR, file), 'utf8');
    const docname = extractDocname(html);
    const tagline = extractTagline(html);
    if (!docname || !tagline) {
      skipped++;
      continue;
    }

    // Start at the reference size (32px source units); the reference
    // git-clone title (58 chars) renders untouched. For longer titles, reduce
    // the font-size until the line's right edge clears the right margin.
    const AVAIL_RIGHT = 1090; // leave a ~110px right margin (of 1200)
    const MIN_FONT = 18;
    let fontSize = 32;
    let svg = cardSvg({ title: tagline, version, fontSize });
    const svgPath = path.join(OUT_DIR, `${docname}.svg`);
    const pngPath = path.join(OUT_DIR, `${docname}.png`);
    fs.writeFileSync(svgPath, svg);
    let rightEdge = await heroRightEdge(page, svgPath);
    if (rightEdge !== null) {
      while (rightEdge > AVAIL_RIGHT && fontSize > MIN_FONT) {
        fontSize -= 2;
        svg = cardSvg({ title: tagline, version, fontSize });
        fs.writeFileSync(svgPath, svg);
        rightEdge = await heroRightEdge(page, svgPath);
        if (rightEdge === null) break;
      }
      if (fontSize < 32) shrunk++;
    }

    await page.screenshot({ path: pngPath, clip: { x: 0, y: 0, width: 1200, height: 630 } });
    fs.unlinkSync(svgPath); // keep only the PNG
    rendered++;
  }
  await browser.close();
  console.log(`Rendered ${rendered} per-page OG cards to ${OUT_DIR} (skipped ${skipped} without a NAME tagline; auto-shrunk ${shrunk} long titles). Git ${version}`);
})().catch((e) => { console.error(e); process.exit(1); });