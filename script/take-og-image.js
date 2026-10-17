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
const CLIP = { x: 40, y: 0, width: 1200, height: 630 };
const OUTPUT = path.join(WORKTREE, 'static', 'images', 'og-image.png');

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