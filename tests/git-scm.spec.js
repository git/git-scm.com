const { test, expect, selectors } = require('@playwright/test')

const url = process.env.PLAYWRIGHT_TEST_URL
  ? process.env.PLAYWRIGHT_TEST_URL.replace(/[^/]$/, '$&/')
  : 'https://git-scm.com/'
const isRailsApp = process.env.PLAYWRIGHT_ASSUME_RAILS_APP === 'true'

// Whenever a test fails, attach a screenshot to diagnose failures better
test.afterEach(async ({ page }, testInfo) => {
  if (testInfo.status !== testInfo.expectedStatus) {
    const screenshotPath =
      testInfo.outputPath(`${testInfo.line}-${testInfo.column}-failure.png`)
    testInfo.attachments.push({
      name: 'screenshot',
      path: screenshotPath,
      contentType: 'image/png'
    })
    await page.screenshot({
      path: screenshotPath,
      timeout: 15000
    })
  }
})

test('generator is Hugo', async ({page}) => {
  await page.goto(url)
  if (isRailsApp) {
    await expect(page.locator('meta[name="generator"]')).toHaveCount(0)
  } else {
    await expect(page.locator('meta[name="generator"]')).toHaveAttribute('content', /^Hugo /)
  }
})

async function pretendPlatform(page, browserName, userAgent, platform) {
  if (browserName !== 'chromium') {
    await page.context().addInitScript({
      content: `Object.defineProperty(navigator, 'platform', { get: () => '${platform}' })`
    })
  } else {
    // As of time of writing, Chromium on Linux (but not on Windows or macOS)
    // refuses to let the `navigator.platform` attribute to be overridden via
    // `Object.defineProperty()`, therefore we use the Chrome DevTools Protocol
    // with that browser (and only with that browser because it is proprietary
    // to that browser).
    const cdpSession = await page.context().newCDPSession(page)
    await cdpSession.send('Emulation.setUserAgentOverride', { platform, userAgent })
  }
}

test.describe('Windows', () => {
  const userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36'
  test.use({ userAgent })

  test('download/GUI links', async ({ page, browserName }) => {
    await pretendPlatform(page, browserName, userAgent, 'Windows')
    await page.goto(url)
    await expect(page.getByRole('link', { name: 'Download for Windows' })).toBeVisible()

    await expect(page.getByRole('link', { name: 'Graphical UIs' })).toBeHidden()
    const windowsGUIs = page.getByRole('link', { name: 'Windows GUIs' })
    await expect(windowsGUIs).toBeVisible()
    await expect(windowsGUIs).toHaveAttribute('href', /\/download\/gui\/windows$/)

    // navigate to Windows GUIs
    await windowsGUIs.click()
    const windowsButton = page.getByRole('link', { name: 'Windows' })
    await expect(windowsButton).toBeVisible()
    await expect(windowsButton).toHaveClass(/selected/)

    const allButton = page.getByRole('link', { name: 'All' })
    await expect(allButton).not.toHaveClass(/selected/)

    const thumbnails = page.locator('.gui-thumbnails li:visible')
    const count = await thumbnails.count()
    await allButton.click()
    await expect.poll(() => thumbnails.count()).toBeGreaterThan(count)
  })
})

test.describe('macOS', () => {
  const userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15'
  test.use({ userAgent })

  test('download/GUI links', async ({ page, browserName }) => {
    await pretendPlatform(page, browserName, userAgent, 'Mac OS X')
    await page.goto(url)
    await expect(page.getByRole('link', { name: 'Download for Mac' })).toBeVisible()

    await expect(page.getByRole('link', { name: 'Graphical UIs' })).toBeHidden()
    await expect(page.getByRole('link', { name: 'Mac GUIs' })).toBeVisible()
  })
})

test.describe('Linux', () => {
  const userAgent = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0'
  test.use({ userAgent })

  test('download/GUI links', async ({ page, browserName }) => {
    await pretendPlatform(page, browserName, userAgent, 'Linux')
    await page.goto(url)
    await expect(page.getByRole('link', { name: 'Download for Linux' })).toBeVisible()

    await expect(page.getByRole('link', { name: 'Graphical UIs' })).toBeHidden()
    await expect(page.getByRole('link', { name: 'Linux GUIs' })).toBeVisible()
  })
})

test('search', async ({ page }) => {
  await page.goto(url)

  // Search for "commit"
  const searchBox = page.getByPlaceholder('Type / to search entire site…')
  await searchBox.fill('commit')
  await searchBox.press('Shift')

  // Expect the div to show up
  const showAllResults = page.getByText('Show all results...')
  await expect(showAllResults).toBeVisible()

  // Expect the first search result to be "git-commit"
  const searchResults = page.locator('#search-results')
  await expect(searchResults.getByRole("link")).not.toHaveCount(0)
  await expect(searchResults.getByRole("link").nth(0)).toHaveText('git-commit')

  // On localized pages, the search results should be localized as well
  await page.goto(`${url}docs/git-commit/fr`)
  await searchBox.fill('add')
  await searchBox.press('Shift')
  if (isRailsApp) {
    await expect(searchResults.getByRole("link").nth(0)).toHaveAttribute('href', /\/docs\/git-add$/)
  } else {
    await expect(searchResults.getByRole("link").nth(0)).toHaveAttribute('href', /\/docs\/git-add\/fr(\.html)?$/)
  }

  // pressing the Enter key should navigate to the full search results page
  await searchBox.press('Enter')
  if (isRailsApp) {
    await expect(page).toHaveURL(/\/search/)
  } else {
    await expect(page).toHaveURL(/\/search.*language=fr/)
  }
})

test('manual pages', async ({ page }) => {
  await page.goto(`${url}docs/git-config`)

  // The summary follows immediately after the heading "NAME", which is the first heading on the page
  const summary = page.locator('xpath=//h2/following-sibling::*[1]').first()
  await expect(summary).toHaveText('git-config - Get and set repository or global options')
  await expect(summary).toBeVisible()

  // Verify that the drop-downs are shown when clicked
  const previousVersionDropdown = page.locator('#previous-versions-dropdown')
  await expect(previousVersionDropdown).toBeHidden()
  if (isRailsApp) {
    await page.getByRole('link', { name: /Version \d+\.\d+\.\d+/ }).click()
  } else {
    await page.getByRole('link', { name: 'Latest version' }).click()
  }
  await expect(previousVersionDropdown).toBeVisible()

  const topicsDropdown = page.locator('#topics-dropdown')
  await expect(topicsDropdown).toBeHidden()
  await page.getByRole('link', { name: 'Topics' }).click()
  await expect(topicsDropdown).toBeVisible()
  await expect(previousVersionDropdown).toBeHidden()

  const languageDropdown = page.locator('#l10n-versions-dropdown')
  await expect(languageDropdown).toBeHidden()
  await page.getByRole('link', { name: 'English' }).click()
  await expect(languageDropdown).toBeVisible()
  await expect(topicsDropdown).toBeHidden()
  await expect(previousVersionDropdown).toBeHidden()

  // Verify that the language is changed when a different language is selected
  await page.getByRole('link', { name: 'Français' }).click()
  await expect(summary).toHaveText('git-config - Lire et écrire les options du dépôt et les options globales')
  await expect(summary).not.toHaveText('git-config - Get and set repository or global options')

  // links to other manual pages should stay within the language when possible,
  // but fall back to English if the page was not yet translated
  const gitRevisionsLink = page.getByRole('link', { name: 'gitrevisions[7]' })
  await expect(gitRevisionsLink).toBeVisible()
  await expect(gitRevisionsLink).toHaveAttribute('href', /\/docs\/gitrevisions\/fr$/)
  await gitRevisionsLink.click()
  await expect(page).toHaveURL(/\/docs\/gitrevisions$/)

  // Ensure that the French mis-translation of `git remote renom` is not present
  await page.goto(`${url}docs/git-remote/fr`)
  const synopsis = page.locator('xpath=//h2[contains(text(), "SYNOPSIS")]/following-sibling::*[1]').first()
  if (isRailsApp) {
    // This is a bug in the Rails app, and it is unclear what the root cause is
    await expect(synopsis).not.toHaveText(/git remote rename.*<ancien> <nouveau>/)
    await expect(synopsis).toHaveText(/git remote renom.*<ancien> <nouveau>/)
  } else {
    await expect(synopsis).toHaveText(/git remote rename.*<ancien> <nouveau>/)
    await expect(synopsis).not.toHaveText(/git remote renom.*<ancien> <nouveau>/)
  }
})

test('book', async ({ page }) => {
  await page.goto(`${url}book/`)
  await expect(page).toHaveURL(/book\/en\/v2/)

  await page.goto(`${url}book`)
  await expect(page).toHaveURL(/book\/en\/v2/)

  // the repository URL is correct
  await expect(page.getByRole('link', { name: 'hosted on GitHub' }))
    .toHaveAttribute('href', 'https://github.com/progit/progit2')

  // Navigate to the first section
  await page.getByRole('link', { name: 'Getting Started' }).click()
  await expect(page).toHaveURL(/Getting-Started-About-Version-Control/)

  // the repository URL is still correct
  await expect(page.getByRole('link', { name: 'hosted on GitHub' }))
    .toHaveAttribute('href', 'https://github.com/progit/progit2')

  // Verify that the drop-down is shown when clicked
  const chaptersDropdown = page.locator('#chapters-dropdown')
  await expect(chaptersDropdown).toBeHidden()
  await page.getByRole('link', { name: 'Chapters' }).click()
  await expect(chaptersDropdown).toBeVisible()

  // Only the current section is marked as active
  await expect(chaptersDropdown.getByRole('link', { name: /About Version Control/ })).toHaveClass(/active/)
  await expect(chaptersDropdown.locator('.active')).toHaveCount(1)

  // Navigate to the French translation
  if (await page.evaluate(() => matchMedia('(max-width: 940px)').matches)) {
    // On small screens, the links to the translated versions of the ProGit book
    // are hidden by default, and have to be "un-hidden" by clicking on the
    // sidebar button first.
    await page.locator('.sidebar-btn').click();
  }
  await page.getByRole('link', { name: 'Français' }).click()
  await expect(page).toHaveURL(/book\/fr/)
  await expect(page.getByRole('link', { name: 'Démarrage rapide' })).toBeVisible()

  // the repository URL now points to the French translation
  await expect(page.getByRole('link', { name: 'hosted on GitHub' }))
    .toHaveAttribute('href', 'https://github.com/progit/progit2-fr')

  // Navigate to a page whose URL contains a question mark
  await page.goto(`${url}book/az/v2/Başlanğıc-Git-Nədir?`)
  if (isRailsApp) {
    await expect(page).toHaveURL(/book\/az\/v2$/)
    await page.goto(`${url}book/az/v2/Başlanğıc-Git-Nədir%3F`)
  } else {
    await expect(page).toHaveURL(/Ba%C5%9Flan%C4%9F%C4%B1c-Git-N%C9%99dir%3F/)
  }
  await expect(page.getByRole('document')).toHaveText(/Snapshot’lar, Fərqlər Yox/)

  // the repository URL now points to the Azerbaijani translation
  await expect(page.getByRole('link', { name: 'hosted on GitHub' }))
    .toHaveAttribute('href', 'https://github.com/progit2-aze/progit2')
})

test('404', async ({ page }) => {
  await page.goto(`${url}does-not.exist`)

  await expect(page.locator('.inner h1')).toHaveText(`That page doesn't exist.`)

  // the 404 page should be styled
  await expect(page.locator('link[rel="stylesheet"]')).toHaveAttribute('href', /application(\.min)?\.css$/)

  // the search box is shown
  await expect(page.locator('#search-text')).toBeVisible()

  // the usual navbar is shown
  await expect(page.getByRole('link', { name: 'Community' })).toBeVisible()
})

test('sidebar', async ({ page }) => {
  await page.goto(`${url}community`);

  test.skip(!await page.evaluate(() => matchMedia('(max-width: 940px)').matches),
    'not a small screen');

  const sidebarButton = page.locator('.sidebar-btn');
  await expect(sidebarButton).toBeVisible();
  await sidebarButton.click();

  const about = page.getByRole('link', { name: 'About', exact: true });
  await expect(about).toBeVisible();
  await about.click();
  await expect(page.getByRole('heading', { name: 'About - Branching and Merging' })).toBeVisible();
});
