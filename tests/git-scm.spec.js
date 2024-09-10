const { test, expect, selectors } = require('@playwright/test')

const url = 'https://git.github.io/git-scm.com/'

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
    const cdpSession = await page.context().newCDPSession(page);
    await cdpSession.send('Emulation.setUserAgentOverride', { platform, userAgent });
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
  await expect(searchResults.getByRole("link").nth(0)).toHaveAttribute('href', /\/docs\/git-add\/fr(\.html)?$/)

  // pressing the Enter key should navigate to the full search results page
  await searchBox.press('Enter')
  await expect(page).toHaveURL(/\/search.*language=fr/)
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
  await page.getByRole('link', { name: 'Latest version' }).click()
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
})

test('book', async ({ page }) => {
  await page.goto(`${url}book`)

  // Navigate to the first section
  await page.getByRole('link', { name: 'Getting Started' }).click()
  await expect(page).toHaveURL(/Getting-Started-About-Version-Control/)

  // Verify that the drop-down is shown when clicked
  const chaptersDropdown = page.locator('#chapters-dropdown')
  await expect(chaptersDropdown).toBeHidden()
  await page.getByRole('link', { name: 'Chapters' }).click()
  await expect(chaptersDropdown).toBeVisible()

  // Only the current section is marked as active
  await expect(chaptersDropdown.getByRole('link', { name: /About Version Control/ })).toHaveClass(/active/)
  await expect(chaptersDropdown.locator('.active')).toHaveCount(1)

  // Navigate to the French translation
  await page.getByRole('link', { name: 'Français' }).click()
  await expect(page).toHaveURL(/book\/fr/)
  await expect(page.getByRole('link', { name: 'Démarrage rapide' })).toBeVisible()
})
