#!/usr/bin/env node

(async () => {
  const options = {
    basePath: {
      option: '--base-path',
      value: 'public/pagefind/',
    },
    language: {
      option: '--language',
      value: 'en',
    },
    limit: {
      option: '--limit',
      type: 'int',
      value: 10
    },
    termFrequency: {
      option: '--term-frequency',
      type: 'float',
      value: 0.1 // do not favor short pages
    },
    termSimilarity: {
      option: '--term-similarity',
      type: 'float',
      value: 9
    },
    termSaturation: {
      option: '--term-saturation',
      type: 'float',
      value: 2
    },
    pageLength: {
      option: '--page-length',
      type: 'float',
      value: 0.1
    },
    json: {
      option: '--json',
      type: 'boolean',
      value: false
    }
  }
  let terms = []

  // Parse command-line options
  const handleValue = (option, value) => {
    if (option.type === 'int') option.value = Number.parseInt(value)
    else if (option.type === 'float') option.value = Number.parseFloat(value)
    else option.value = value
  }

  const args = process.argv.slice(2)
  optionLoop:
  for (let i = 2; i < process.argv.length; i++) {
    for (const key of Object.keys(options)) {
      const option = options[key]
      if (option.type === 'boolean') {
        if (process.argv[i] === option.option) option.value = true
        else if (process.argv[i] === `--no-${option.option}`) option.value = false
        else continue
      } else if (process.argv[i] === option.option) {
        if (++i >= process.argv.length) throw new Error(`\`${option.option}\` requires an argument`)
        handleValue(option, process.argv[i])
      } else if (process.argv[i].startsWith(`${option.option}=`)) {
        const value = process.argv[i].slice(option.option.length + 1)
        handleValue(option, value)
      } else continue
      continue optionLoop
    }
    if (process.argv[i].startsWith('-')) throw new Error(`Unknown option: ${process.argv[i]}`)
    terms.push(...process.argv.slice(i))
    break
  }

  if (terms.length === 0) throw new Error('No search terms provided')

  // Make `basePath` an absolute path
  const path = await import('path')
  if (!path.isAbsolute(options.basePath.value)) options.basePath.value = `${path.resolve(process.cwd(), options.basePath.value)}/`

  const pagefindPath = path.join(options.basePath.value, 'pagefind.js')
  const url = await import('url')
  const pagefindUrl = url.pathToFileURL(pagefindPath).href

  // Cannot use `await import('public/pagefind/pagefind.js')` because
  // `pagefind.js` does not have the `.mjs` file extension yet is an ESM
  // module. This would elicit the warning and error:
  //
  //   Warning: To load an ES module, set "type": "module" in the package.json or use the .mjs extension.
  //   [...]
  //   SyntaxError: Cannot use 'import.meta' outside a module
  //
  // Instead, we load the file contents and dynamically import them via a data URL.
  const fs = await import('fs')
  const contents = await fs.promises.readFile(pagefindPath)
  const moduleUrl = `data:application/javascript;base64,${contents.toString('base64')}`
  // Dynamically import the module from the blob URL
  const pagefind = await import(moduleUrl)

  // Emulate the globals that the `pagefind.js` script expects to find in the
  // browser environment.
  Object.assign(globalThis, {
    window: {
      location: {
        origin: ''
      }
    },
    document: {
      querySelector: () => {
        return {
          getAttribute: () => {
            return 'en'
          }
        }
      }
    },
    location: {
      href: pagefindUrl
    },
    fetch: async url => {
      const match = url.match(/(.*)\?.*$/)
      const contents = await fs.promises.readFile(match ? match[1] : url)
      return {
        ...contents,
        arrayBuffer: () => contents,
        json: () => JSON.parse(contents),
      }
    }
  })

  const pagefindOptions = {
    basePath: options.basePath.value,
    ranking: ['termFrequency', 'termSaturation', 'termSimilarity', 'pageLength'].reduce((v, c) => {
      if (options[c].value !== undefined) v[c] = options[c].value
      return v
    }, {})
  }

  pagefind.options(pagefindOptions)
  await pagefind.init(options.language.value)

  for (const term of terms) {
    let results = await pagefind.debouncedSearch(term)
    results = options.limit.value < 1 ? results.results : results.results.slice(0, options.limit.value)
    await Promise.all(results.map(async (item, index) => {
      item.index = index
      item.data = await item.data()
    }))
    console.log(`Results for ${term}:\n${options.json.value
      ? JSON.stringify(results, null, 2)
      : results.map(item => `${item.index + 1}. ${item.data.raw_url} (${item.score})`).join('\n')
    }`)
  }
})().catch(e => {
  process.stderr.write(`${e}\n`)
  process.exit(1)
})
