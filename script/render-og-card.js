#!/usr/bin/env node
// Generate static/images/og-image.png (1200x630) — the site-wide social card
// used as the fallback for non-docs pages (homepage, book, etc.).
//
// Design source: the maintainers' own SVG (To1ne's proposal, posted by dscho
// on PR #2233) — script/og-card-design.svg. This script loads that exact file
// and substitutes only the hero title (tspan #tspan4) with "Git" and the
// version pill (tspan #tspan6) with the current version. Everything else —
// logo, colors, fonts, sizes, transforms — comes verbatim from the
// maintainers' file, so the site-wide card matches the per-page docs cards
// and the maintainers' reference pixel-for-pixel.
//
// Usage:
//   node script/render-og-card.js [worktree-path]
//
// The version is read from hugo.yml (latest_version) at render time, so the
// card stays in sync whenever a new Git version is published. The image is
// regenerated as part of the Git version-bump workflow — see
// `.github/workflows/update-git-version-and-manual-pages.yml`.
//
// Rendered with the repo's existing Playwright/Chromium stack.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const WORKTREE = path.resolve(process.argv[2] || '.');
const OUT = path.join(WORKTREE, 'static', 'images', 'og-image.png');
const DESIGN = fs.readFileSync(path.join(WORKTREE, 'script', 'og-card-design.svg'), 'utf8');

function currentVersion() {
  const hugo = fs.readFileSync(path.join(WORKTREE, 'hugo.yml'), 'utf8');
  const m = hugo.match(/^\s*latest_version:\s*([0-9][^\s]*)/m);
  if (!m) throw new Error('Could not find latest_version in hugo.yml');
  return m[1];
}

function cardSvg(version) {
  // The design SVG carries all-upper-case PLACEHOLDERS for the two variable
  // values (hero title and version pill). Replace them verbatim — no regex.
  return DESIGN
    .replace('__HERO_TITLE__', 'Git')
    .replace('__HERO_FONT_SIZE__', '32')
    .replace('__VERSION__', version);
}

(async () => {
  const version = currentVersion();
  const svg = cardSvg(version);
  const svgPath = path.join(WORKTREE, 'script', 'og-card.svg');
  fs.writeFileSync(svgPath, svg);

  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });
  await page.goto('file://' + svgPath);
  await page.waitForTimeout(200);
  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  await page.screenshot({ path: OUT, clip: { x: 0, y: 0, width: 1200, height: 630 } });
  await browser.close();
  console.log(`Wrote ${OUT} (Git ${version})`);
})().catch((e) => { console.error(e); process.exit(1); });