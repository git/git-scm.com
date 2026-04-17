#!/usr/bin/env node
// @ts-check

const usage = `Generate before/after screenshots for two URLs using Playwright.

Usage:
  node script/compare-screenshots.js [options] <before-url> <after-url>

Arguments can be URLs or paths to git-scm.com worktrees. When a worktree
path is given, Hugo is run to build the site and a local server is started.
Use worktree@commit to checkout a specific commit before building.
Use worktree:/path/to/page to navigate to a specific page.
Both can be combined: worktree@commit:/path/to/page
As a convenience, @commit implies the current directory, and @{u} is
treated as @@{u} since refs cannot start with a curly brace.

Options:
  --dark              Emulate dark mode (prefers-color-scheme: dark)
  --light             Emulate light mode (default)
  --clip=<WxH+X+Y>    Clip screenshots to specified region (e.g., --clip=1280x720+0+0)

Examples:
  node script/compare-screenshots.js https://git-scm.com http://localhost:5000
  node script/compare-screenshots.js https://git-scm.com /path/to/worktree
  node script/compare-screenshots.js https://git-scm.com @HEAD~2
  node script/compare-screenshots.js @{u} .
  node script/compare-screenshots.js https://git-scm.com/docs/git-config /path/to/worktree:/docs/git-config
  node script/compare-screenshots.js --dark https://git-scm.com http://localhost:5000
  node script/compare-screenshots.js --clip=1280x720+0+0 https://git-scm.com http://localhost:5000`;

const { chromium } = require('@playwright/test');
const { spawn, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

let lastPagePath;

/**
 * Parse a worktree argument to extract worktree path, commit, and page path.
 *
 * Format: [worktree][@commit][:/page/path]
 *
 * Examples:
 *   .                    -> { worktreePath: '.', commit: undefined, pagePath: '' }
 *   @HEAD~2              -> { worktreePath: '.', commit: 'HEAD~2', pagePath: '' }
 *   .@HEAD~2             -> { worktreePath: '.', commit: 'HEAD~2', pagePath: '' }
 *   @{u}                 -> { worktreePath: '.', commit: '@{u}', pagePath: '' }
 *   /path/to/worktree:/docs/git -> { worktreePath: '/path/to/worktree', commit: undefined, pagePath: 'docs/git' }
 *   .@main:/about        -> { worktreePath: '.', commit: 'main', pagePath: 'about' }
 *
 * If no page path is specified, inherits the page path from the previous call.
 *
 * Returns false if the argument is a URL or not a valid worktree.
 */
function getWorktreeInfo(arg) {
  if (arg.startsWith('http://') || arg.startsWith('https://')) {
    // Extract path from URL for inheritance
    try {
      lastPagePath = new URL(arg).pathname.replace(/^\/+/, '');
    } catch {
    }
    return false;
  }
  // Allow @commit as shorthand for .@commit (current directory)
  if (arg.startsWith('@')) arg = '.' + arg;
  const colonIndex = arg.indexOf(':');
  const beforeColon = colonIndex === -1 ? arg : arg.slice(0, colonIndex);
  let pagePath = colonIndex === -1 ? undefined : arg.slice(colonIndex + 1).replace(/^\/+/, '');
  const atIndex = beforeColon.indexOf('@');
  const worktreePath = atIndex === -1 ? beforeColon : beforeColon.slice(0, atIndex);
  let commit = atIndex === -1 ? undefined : beforeColon.slice(atIndex + 1);
  // Allow @{u} as shorthand for @@{u} since refs can't start with {
  if (commit && commit.startsWith('{')) commit = '@' + commit;
  // Inherit page path from previous call if not specified
  if (pagePath === undefined && lastPagePath !== undefined) {
    pagePath = lastPagePath;
  } else if (pagePath !== undefined) {
    lastPagePath = pagePath;
  }
  try {
    if (fs.statSync(path.join(worktreePath, 'hugo.yml')).isFile()) {
      return { worktreePath, commit, pagePath: pagePath || '' };
    }
  } catch {
  }
  return false;
}

async function startServer(worktreePath, port, commit) {
  let restoreRef;
  let wasDetached = false;

  if (commit) {
    // Determine if we're on a branch (symbolic ref) or detached HEAD
    try {
      restoreRef = execSync('git symbolic-ref --short HEAD', { cwd: worktreePath, encoding: 'utf-8' }).trim();
    } catch {
      // Not on a branch, save the commit SHA
      restoreRef = execSync('git rev-parse HEAD', { cwd: worktreePath, encoding: 'utf-8' }).trim();
      wasDetached = true;
    }
    console.log(`Switching to ${commit} in ${worktreePath}...`);
    execSync(`git switch -d ${commit}`, { cwd: worktreePath, stdio: 'inherit' });
  }

  // Build Hugo site
  console.error(`Building Hugo site in ${worktreePath}...`);
  execSync('hugo', { cwd: worktreePath, stdio: 'inherit' });

  // Start serve-public.js
  const serverScript = path.join(worktreePath, 'script', 'serve-public.js');
  const server = spawn('node', [serverScript], {
    cwd: worktreePath,
    env: { ...process.env, PORT: String(port) },
    stdio: ['ignore', 'pipe', 'inherit'],
  });

  // Attach restore function to server
  server.restore = () => {
    if (restoreRef) {
      console.log(`Restoring ${worktreePath} to ${restoreRef}...`);
      if (wasDetached) {
        execSync(`git switch -d ${restoreRef}`, { cwd: worktreePath, stdio: 'inherit' });
      } else {
        execSync(`git switch ${restoreRef}`, { cwd: worktreePath, stdio: 'inherit' });
      }
    }
  };

  // Wait for server to be ready
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
  const args = process.argv.slice(2);
  const options = {
    viewport: { width: 1280, height: 720 },
    ignoreHTTPSErrors: true,
    colorScheme: 'light',
  };
  let clip;

  const urls = args.filter(arg => {
    if (!arg.startsWith('--')) return true;

    if (arg === '--dark') {
      options.colorScheme = 'dark';
    } else if (arg === '--light') {
      options.colorScheme = 'light';
    } else if (arg.startsWith('--clip=')) {
      const match = arg.slice(7).match(/^(\d+)x(\d+)\+(\d+)\+(\d+)$/);
      if (!match) {
        console.error(`Invalid clip format: ${arg} (expected --clip=WxH+X+Y)`);
        process.exit(1);
      }
      clip = {
        width: parseInt(match[1], 10),
        height: parseInt(match[2], 10),
        x: parseInt(match[3], 10),
        y: parseInt(match[4], 10),
      };
      // Ensure viewport is large enough to contain the clip region
      options.viewport = {
        width: Math.max(options.viewport.width, clip.x + clip.width),
        height: Math.max(options.viewport.height, clip.y + clip.height),
      };
    } else {
      console.error(`Unknown option: ${arg}`);
      process.exit(1);
    }
    return false;
  });

  if (urls.length !== 2) {
    console.error(usage);
    process.exit(1);
  }

  const beforeUrl = urls[0];
  const afterUrl = urls[1];

  const browser = await chromium.launch();

  try {
    const context = await browser.newContext(options);

    const page = await context.newPage();

    if (options.colorScheme === 'dark') {
      console.error('Using dark mode (prefers-color-scheme: dark)');
    }

    async function takeScreenshot(urlOrWorktree, outputPath) {
      let server;
      let url = urlOrWorktree;

      const worktreeInfo = getWorktreeInfo(urlOrWorktree);
      if (worktreeInfo) {
        server = await startServer(worktreeInfo.worktreePath, 5000, worktreeInfo.commit);
        url = `http://localhost:5000/${worktreeInfo.pagePath}`;
      }

      try {
        console.error(`Navigating to: ${url}`);
        await page.goto(url, { waitUntil: 'networkidle' });
        await page.screenshot({ path: outputPath, clip, fullPage: !clip });
        const pageDims = await page.evaluate(() => ({
          width: document.documentElement.scrollWidth,
          height: document.documentElement.scrollHeight,
        }));
        const info = clip
          ? `${clip.width}x${clip.height}+${clip.x}+${clip.y} of ${pageDims.width}x${pageDims.height}`
          : `${pageDims.width}x${pageDims.height}`;
        console.error(`Saved: ${outputPath} (${info})`);
      } finally {
        if (server) {
          server.kill();
          server.restore();
        }
      }
    }

    await takeScreenshot(beforeUrl, '.before.png');
    await takeScreenshot(afterUrl, '.after.png');

    console.error(`\nScreenshots saved:`);
    console.error('  - .before.png');
    console.error('  - .after.png');

    console.error(`\nPR comment template (copy paths, then replace by uploading images):\n`);
    console.log(`<!-- Generated by 'node ${
      process.argv
        .slice(1)
        .map((e, i) => i != 1 ? e : e.replace(/.*[/\\]/, ''))
        .join(' ')
    }' -->`);
    console.log(`<table>`);
    console.log(`<tr><th>Before</th><th>After</th></tr>`);
    console.log(`<tr>`);
    console.log(`<td>`);
    console.log(path.resolve('.before.png'));
    console.log(`</td>`);
    console.log(`<td>`);
    console.log(path.resolve('.after.png'));
    console.log(`</td>`);
    console.log(`</tr>`);
    console.log(`</table>`);
  } finally {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
