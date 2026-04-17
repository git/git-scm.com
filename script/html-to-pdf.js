#!/usr/bin/env node

const fs = require('fs')
const path = require('path')
const url = require('url')
const { chromium } = require('playwright')

const insertPDFLink = (htmlPath) => {
  const html = fs.readFileSync(htmlPath, 'utf-8')
  if (html.includes('class="pdf-link"')) {
    return
  }
  // get baseURL prefix via the `favicon.ico` link, it's in the top-level directory
  const match = html.match(/<link href="(.*?)favicon\.ico"/)
  if (!match) throw new Error('Failed to determine baseURL prefix from favicon.ico link')
  const img = `<img src="${match[1].replace(/\/$/, '')}/images/pdf.png" />`
  const updatedHtml = html.replace(
    /<h1/,
    `<a class="pdf-link" href="${path.basename(htmlPath, '.html')}.pdf">${img}</a>$&`
  )
  if (updatedHtml === html) throw new Error('Failed to insert PDF link, no <h1> found')
  fs.writeFileSync(htmlPath, updatedHtml, 'utf-8')
}

const htmlToPDF = async (htmlPath, options) => {
  if (!htmlPath.endsWith('.html')) {
    throw new Error(`Input file must have the '.html' extension: ${htmlPath}`)
  }
  if (!fs.existsSync(htmlPath)) {
    throw new Error(`Input file does not exist: ${htmlPath}`)
  }
  const outputPath = htmlPath.replace(/\.html$/, '.pdf')
  if (!options.force && fs.existsSync(outputPath)) {
    throw new Error(`Output file already exists: ${outputPath}`)
  }

  const browser = await chromium.launch({ channel: 'chrome', ...(options.devtools ? { devtools: true } : {}) })
  const page = await browser.newPage()

  const htmlPathURL = url.pathToFileURL(htmlPath).toString()
  console.log(`Processing ${htmlPathURL}...`)

  // Work around HUGO_RELATIVEURLS=false by rewriting the absolute URLs
  const baseURLPrefix = htmlPathURL.substring(0, htmlPathURL.lastIndexOf('/public/') + 8)
  await page.route(/^file:\/\//, async (route, req) => {
    // This _will_ be a correct URL when deployed to https://whatevers/, but
    // this script runs before deployment, on a file:/// URL, where we need to
    // be a bit clever to give the browser the file it needs.
    const original = req.url()
    if (original === htmlPathURL) {
      // Work around rerouted `.css` and `.js` files... Symptom: "has an
      // integrity attribute, but the resource requires the request to be CORS
      // enabled to check the integrity, and it is not. The resource has been
      // blocked because the integrity cannot be enforced."
      const body =
        fs.readFileSync(htmlPath, "utf-8")
	  // strip out the `integrity="sha256-..."` attributes
          .replace(/(\/application\.[^"/]+") integrity="sha256-[^"]+"/g, "$1")
      await route.fulfill({ headers: { "Content-Type": "text/html" }, body })
      return
    }

    const url =
      original.startsWith(baseURLPrefix)
        ? original
        : original.replace(/^file:\/\/\/([A-Za-z]:\/)?(git-scm\.com\/)?/, baseURLPrefix)
    if (url !== original) console.error(`::notice::Rewrote ${original} to ${url}`)
    await route.continue({ url })
  })

  await page.goto(htmlPathURL, { waitUntil: 'load' })

  await page.pdf({
    path: outputPath,
    format: 'A4',
    landscape: true,
    margin: { top: '0cm', bottom: '0cm', left: '0cm', right: '0cm' },
  })
  if (options.devtools) await new Promise((resolve) => { setTimeout(resolve, 5 * 60 * 1000) })
  await browser.close()

  if (options.insertPDFLink) insertPDFLink(htmlPath)
}

const args = process.argv.slice(2)
const options = {}
while (args?.[0].startsWith('-')) {
  const arg = args.shift()
  if (arg === '--force' || arg === '-f') options.force = true
  else if (arg === '--insert-pdf-link' || arg === '-i') options.insertPDFLink = true
  else if (arg === '--devtools' || arg === '-d') options.devtools = true
  else throw new Error(`Unknown argument: ${arg}`)
}

if (args.length !== 1) {
  process.stderr.write('Usage: html-to-pdf.js [--force] [--insert-pdf-link] <input-file.html>\n')
  process.exit(1)
}

htmlToPDF(args[0], options).catch(e => {
  process.stderr.write(`${e.stack}\n`)
  process.exit(1)
})
