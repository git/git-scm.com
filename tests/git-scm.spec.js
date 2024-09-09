const { test, expect, selectors } = require('@playwright/test')

const url = 'https://git.github.io/git-scm.com/'

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
