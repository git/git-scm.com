#!/usr/bin/env node
// Generate static/images/og-image.png (1200x630) — a simple, hand-made social
// card with the official Git logo, a one-line tagline, and the current version.
//
// Usage:
//   node script/render-og-card.js [worktree-path]
//
// The version is read from hugo.yml (latest_version) at render time, so the
// card stays in sync whenever a new Git version is published. The image is
// regenerated as part of the Git version-bump workflow — see
// `.github/workflows/update-git-version-and-manual-pages.yml`.
//
// Rendered with the repo's existing Playwright/Chromium stack (same as
// script/compare-screenshots.js), so no new language or toolchain is added.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const WORKTREE = path.resolve(process.argv[2] || '.');
const OUT = path.join(WORKTREE, 'static', 'images', 'og-image.png');

function currentVersion() {
  const hugo = fs.readFileSync(path.join(WORKTREE, 'hugo.yml'), 'utf8');
  const m = hugo.match(/^\s*latest_version:\s*([0-9][^\s]*)/m);
  if (!m) throw new Error('Could not find latest_version in hugo.yml');
  return m[1];
}

function cardSvg(version) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#fafafa"/>
      <stop offset="1" stop-color="#f0f0f0"/>
    </linearGradient>
  </defs>
  <rect width="1200" height="630" fill="url(#bg)"/>
  <rect x="0" y="0" width="1200" height="6" fill="#f03c2e"/>

  <!-- Official Git logo (2-color mark: orange icon + dark "git" text) -->
  <g transform="translate(120 150) scale(3.2)">
    <path fill="#f03c2e" transform="scale(1.179487) translate(10 10) rotate(-45 29 29)" d="M5,58c-2.76142,0 -5,-2.23858 -5,-5v-48c0,-2.76142 2.23858,-5 5,-5h33v12.54404c-2.06553,0.94801 -3.5,3.03446 -3.5,5.45596c0,0.73514 0.13221,1.43941 0.37415,2.09031l-15.28384,15.28384c-0.6509,-0.24194 -1.35517,-0.37415 -2.09031,-0.37415c-3.31371,0 -6,2.68629 -6,6c0,3.31371 2.68629,6 6,6c3.31371,0 6,-2.68629 6,-6c0,-0.73514 -0.13221,-1.43941 -0.37415,-2.09031l14.87415,-14.87415l0,11.50851c-2.06553,0.94801 -3.5,3.03446 -3.5,5.45596c0,3.31371 2.68629,6 6,6c3.31371,0 6,-2.68629 6,-6c0,-2.42149 -1.43447,-4.50795 -3.5,-5.45596l0,-12.08808c2.06553,-0.94801 3.5,-3.03446 3.5,-5.45596c0,-2.42149 -1.43447,-4.50795 -3.5,-5.45596l0,-12.54404h10c2.76142,0 5,2.23858 5,5v48c0,2.76142 -2.23858,5 -5,5z"/>
  </g>

  <!-- Title -->
  <text x="120" y="330" font-family="Helvetica, Arial, sans-serif" font-size="96" font-weight="bold" fill="#362701">Git</text>

  <!-- Tagline -->
  <text x="120" y="400" font-family="Helvetica, Arial, sans-serif" font-size="34" fill="#555555">A free and open source distributed version control system</text>

  <!-- Version -->
  <g transform="translate(120 470)">
    <rect x="0" y="0" width="300" height="64" rx="32" fill="#f03c2e"/>
    <text x="150" y="42" font-family="Helvetica, Arial, sans-serif" font-size="30" font-weight="bold" fill="#ffffff" text-anchor="middle">Latest: v${version}</text>
  </g>

  <!-- URL -->
  <text x="120" y="580" font-family="Helvetica, Arial, sans-serif" font-size="26" fill="#888888">git-scm.com</text>
</svg>`;
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
