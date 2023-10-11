const fs = require('fs')

const getFileContents = async (path) => {
    return (await fs.promises.readFile(path)).toString('utf-8').trim()
}

const getAllBooks = async () => {
  const book_rb = await getFileContents("script/book.rb");
  const begin = book_rb.indexOf('@@all_books = {')
  const end = book_rb.indexOf('}', begin + 1)
  if (begin < 0 || end < 0) throw new Error(`Could not find @@all_books in:\n${book_rb}`)
  return book_rb
  .substring(begin, end)
  .split('\n')
  .reduce((allBooks, line) => {
      const match = line.match(/"([^"]+)" => "([^"]+)"/)
      if (match) allBooks[match[1]] = match[2]
      return allBooks
  }, {})
}

const getPendingBookUpdates = async (octokit, forceRebuild) => {
  const books = await getAllBooks()
  const result = []
  for (const lang of Object.keys(books)) {
    if (!forceRebuild) {
      try {
        const localSha = await getFileContents(`_sync_state/book-${lang}.sha`)

        const [owner, repo] = books[lang].split('/')
        const { data: { default_branch: remoteDefaultBranch } } =
          await octokit.rest.repos.get({
            owner,
            repo
          })
        const { data: { object: { sha: remoteSha } } } =
          await octokit.rest.git.getRef({
            owner,
            repo,
            ref: `heads/${remoteDefaultBranch}`
          })

        if (localSha === remoteSha) continue
      } catch (e) {
        // It's okay for the `.sha` file not to exist yet.`
        if (e.code !== 'ENOENT') throw e
      }
    }
    result.push({
      lang,
      repository: books[lang]
    })
  }
  return result
}

// for testing locally, needs `npm install @octokit/rest` to work
if (require.main === module) {
  (async () => {
    const { Octokit } = require('@octokit/rest')
    console.log(await getPendingBookUpdates(new Octokit()))
  })().catch(console.log)
}

module.exports = {
  getPendingBookUpdates
}