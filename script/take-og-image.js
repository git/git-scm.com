#!/usr/bin/env node
// @ts-check

/**
 * Generate a 1200x630 Open Graph image for git-scm.com by taking a real
 * screenshot of the built site, so the card reflects the site's actual look
 * and feel.
 *
 * Usage:
 *   node script/take-og-image.js [worktree-path]
 *
 * The optional WORKTREE-PATH points at a git-scm.com worktree (default: the
 * current directory). The script builds the site with Hugo, serves the built
 * site with script/serve-public.js, captures the homepage in light mode at a
 * 1200x630 clip, and writes the result to static/images/og-image.png in that
 * worktree.
 *
 * The card keeps the "Latest source release" box (and thus the current version
 * number, which comes from the site config) visible. The image is regenerated
 * as part of the Git version-bump workflow, so the version shown in the card
 * stays in sync whenever a new Git version is published — see
 * `.github/workflows/update-git-version-and-manual-pages.yml`.
 *
 * This mirrors the repo's existing screenshot tooling
 * (script/compare-screenshots.js) — same build/serve helpers, same Playwright
 * stack — so the OG image is a genuine snapshot of the site rather than a
 * hand-drawn card that would look nothing like git-scm.com.
 */

const { chromium } = require('@playwright/test');
const { spawn, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const WORKTREE = path.resolve(process.argv[2] || '.');
const PORT = 5100;
const VIEWPORT = { width: 1280, height: 720 };
// 1200x630 social card: header + hero + the first two rows of the feature
// grid, plus the "Latest source release" box on the right (which carries the
// current version). Lower-page content is hidden so the card reads as a
// complete, current snapshot of the site.
const CLIP = { x: 40, y: 0, width: 1200, height: 630 };
const OUTPUT = path.join(WORKTREE, 'static', 'images', 'og-image.png');

/**
 * Compose the screenshot region: keep the "Latest source release" box (which
 * shows the current version number) and the first two feature-grid rows, hide
 * the Pro Git promo row and the lower-page content so the clip reads as a
 * complete, timeless view of the site. The version number itself is not
 * hard-coded here — it comes from the site config at build time, and the image
 * is regenerated on every Git version bump (see the version-bump workflow).
 */
async function composeForScreenshot(page) {
  await page.evaluate(() => {
    const hide = (sel) => document.querySelectorAll(sel).forEach((el) => { el.style.display = 'none'; });
    hide('#front-book');      // Pro Git promo row below the feature grid
    hide('footer');           // keep the 1200x630 clip on the page content
    // Keep only the first two feature-grid rows so the 1200x630 clip ends on a
    // clean boundary instead of slicing the "Install"/"Community" row.
    const lis = document.querySelectorAll('#front-nav ul li');
    for (let i = 4; i < lis.length; i++) lis[i].style.display = 'none';
    const ul = document.querySelector('#front-nav ul');
    if (ul) ul.style.paddingBottom = '24px';
  });
}

async function startServer() {
  console.error(`Building Hugo site in ${WORKTREE}...`);
  execSync('hugo', { cwd: WORKTREE, stdio: 'inherit' });

  const serverScript = path.join(WORKTREE, 'script', 'serve-public.js');
  const server = spawn('node', [serverScript], {
    cwd: WORKTREE,
    env: { ...process.env, PORT: String(PORT) },
    stdio: ['ignore', 'pipe', 'inherit'],
  });

  await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Server startup timeout')), 30000);
    server.stdout.on('data', (data) => {
      if (data.toString().includes('Now listening')) {
        clearTimeout(timeout);
        resolve();
      }
    });
    server.on('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });

  return server;
}

async function main() {
  const server = await startServer();
  const browser = await chromium.launch();

  try {
    const context = await browser.newContext({
      viewport: VIEWPORT,
      colorScheme: 'light',
    });
    const page = await context.newPage();

    console.error(`Navigating to: http://localhost:${PORT}/`);
    await page.goto(`http://localhost:${PORT}/`, { waitUntil: 'networkidle' });

    await composeForScreenshot(page);

    fs.mkdirSync(path.dirname(OUTPUT), { recursive: true });
    await page.screenshot({ path: OUTPUT, clip: CLIP });
    console.error(`Saved: ${OUTPUT} (${CLIP.width}x${CLIP.height} clip of the homepage)`);
  } finally {
    await browser.close();
    server.kill();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});