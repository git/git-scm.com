# Git Homepage

[![CI](https://github.com/git/git-scm.com/actions/workflows/ci.yml/badge.svg)](https://github.com/git/git-scm.com/actions/workflows/ci.yml)
[![Help Contribute to Open Source](https://www.codetriage.com/git/git-scm.com/badges/users.svg)](https://www.codetriage.com/git/git-scm.com)

Welcome to the repository for [git-scm.com](https://git-scm.com), the official website for Git. This site is designed to be the starting point for anyone interested in downloading, learning about, or contributing to the Git SCM system. The site is built with [Hugo](https://gohugo.io/) and served via GitHub Pages.

---

## Table of Contents

- [Getting Started](#getting-started)
  - [Cloning the Repository](#cloning-the-repository)
  - [Directory Structure](#directory-structure)
- [Local Development](#local-development)
  - [Prerequisites](#prerequisites)
  - [Serving the Site Locally](#serving-the-site-locally)
  - [Enabling Search Locally](#enabling-search-locally)
- [Testing](#testing)
- [Content Updates](#content-updates)
  - [Manual Pages](#manual-pages)
  - [Downloads Data](#downloads-data)
  - [ProGit Book](#progit-book)
- [Contributing](#contributing)
- [Adding a New GUI Client](#adding-a-new-gui-client)
- [Useful Links](#useful-links)
- [License](#license)

---

## Getting Started

### Cloning the Repository

#### 1. Recommended Approach: Using Scalar

We recommend using [`scalar`](https://git-scm.com/docs/scalar) for an efficient and focused clone. This allows you to work only on the parts of the repository relevant to your interests.

```console
scalar clone https://github.com/git/git-scm.com
cd git-scm.com/src
git sparse-checkout set layouts content static assets hugo.yml data script
```

#### 2. Alternative: Manual Sparse Clone

If `scalar` is not available, you can perform a sparse, partial clone manually:

```console
git clone --filter=blob:none --no-checkout https://github.com/git/git-scm.com
cd git-scm.com
git sparse-checkout set layouts content static assets hugo.yml data script
git reset --hard
```

> **Note:**  
> If you already have a full clone and wish to focus on a subset of the repository, you may use the `git sparse-checkout set [...]` command as shown above.

### Directory Structure

- **layouts/**, **content/**, **static/**, **assets/**: For testing page rendering with Hugo.
- **data/**: For adding new GUI client data.
- **script/**: For pre-rendering pages sourced from other repositories (e.g., ProGit book).
- **.github/**: Contains GitHub workflow configurations.
- **external/book/**, **external/docs/**: Pre-rendered pages (do not edit directly).

---

## Local Development

### Prerequisites

- [Hugo](https://gohugo.io/), **extended** version v0.128.0 or later.
- [Node.js](https://nodejs.org/).
- On Windows, it is recommended to use Windows Subsystem for Linux (WSL) due to file naming constraints.

Verify your Hugo installation:

```console
$ hugo version
hugo v0.128.0+extended linux/amd64 BuildDate=unknown
```

### Serving the Site Locally

To serve the site using the provided script:

```console
node script/serve-public.js
```

The site will be available at [http://127.0.0.1:5000](http://127.0.0.1:5000).

Alternatively, to use Hugo's built-in server (served at [http://127.0.0.1:1313](http://127.0.0.1:1313)), disable "ugly URLs":

```console
HUGO_UGLYURLS=false hugo serve -w
```

> **Note:**  
> "Ugly URLs" refer to URLs ending with `.html` (e.g., `/about.html`). GitHub Pages prefers these for compatibility. The `serve-public.js` script emulates this behavior.

### Enabling Search Locally

To test the site with search enabled:

```console
hugo
npx -y pagefind --site public
node script/serve-public.js
```

Alternatively, to use Pagefind's built-in server (at [http://127.0.0.1:1414](http://127.0.0.1:1414)):

```console
HUGO_UGLYURLS=false hugo
npx -y pagefind --site public --serve
```

> **Note:**  
> Running Pagefind may slow down the process and disables live reloading.

---

## Testing

The site includes a test suite using [Playwright](https://playwright.dev/) to verify UI correctness. Tests are located in the `tests/` directory and configured via `playwright.config.js`.

### Running Tests

1. Install Playwright:

    ```console
    npm install @playwright/test
    ```

---

### 2. Install a browser for Playwright tests (e.g., Firefox)

Playwright supports several browsers including `firefox`, `chromium`, `webkit`, and `chrome`. You can install a specific browser like Firefox using:

```console
npx playwright install firefox
```

> **Note:**  
> You can install all supported browsers with `npx playwright install`, but be aware that each browser download is over 100MB. To save space and time, install only the browsers you need.  
> In GitHub Actions hosted runners, Chrome is pre-installed, and you might also be able to use your local Chrome installation.

---

### 3. Run tests against your local site

By default, Playwright tests run against [https://git-scm.com/](https://git-scm.com/). To test your local changes, run a local server (e.g., on `http://localhost:5000/`) and then run the tests targeting it:

```console
PLAYWRIGHT_TEST_URL='http://localhost:5000/' npx playwright test --project=firefox
```

You can also run specific tests matching a pattern using `-g <regex>` for more fine-grained testing.

---

## Content Updates

### Manual Pages

1. Install Ruby prerequisites:

    ```console
    bundler install
    ```

2. Build manual pages from a local Git clone:

    ```console
    ruby ./script/update-docs.rb /path/to/git/.git en
    ```

   To build for a specific version:

    ```console
    version=v2.23.0
    REBUILD_DOC=$version ruby ./script/update-docs.rb /path/to/git/.git en
    ```

   To build from GitHub (slower):

    ```console
    export GITHUB_API_TOKEN=github_personal_auth_token
    REBUILD_DOC=$version ruby ./script/update-docs.rb remote en
    ```

   For localized man pages, use a local clone of [git-html-l10n](https://github.com/jnavila/git-html-l10n):

    ```console
    ruby ./script/update-docs.rb /path/to/git-html-l10n/.git l10n
    REBUILD_DOC=$version ruby ./script/update-docs.rb /path/to/git-html-l10n/.git l10n
    ```

### Downloads Data

Update the downloads data for the site:

```console
ruby ./script/update-download-data.rb
```

### ProGit Book

1. Install prerequisites:

    ```console
    bundler install
    ```

That will generate the book content from the Asciidoc files and write the files to the local tree, ready to be committed and served via Hugo.

Alternatively, you need to have access to the [Pro Git project on GitHub](https://github.com/progit/progit2) through the API.

```console
$ export GITHUB_API_TOKEN=github_personal_auth_token
$ ruby ./script/update-book2.rb en
```

If you have 2FA enabled, you'll need to create a [Personal Access Token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/).

If you want to build the book for all available languages, just omit the language code parameter:

```console
$ ruby ./script/update-book2.rb
```

## Contributing

If you wish to contribute to this website, please [fork it on GitHub](https://github.com/git/git-scm.com).

Then, clone it using [`scalar`](https://git-scm.com/docs/scalar) (this avoids long clone times) and then use [`git sparse-checkout add <directory>`](https://git-scm.com/docs/git-sparse-checkout) to check out the files relevant to your work.

After making the changes, commit and push to a named branch in your fork, then open a pull request. If it is a big feature, you might want to [start an issue](https://github.com/git/git-scm.com/issues/new) first to make sure it's something that will be accepted.

## Adding a new GUI

The [list of GUI clients](https://git-scm.com/downloads/guis) has been constructed by the community for a long time. If you want to add another tool you'll need to follow a few steps:

1. Add a new `.md` file with the GUI client details: data/guis
    1. The fields need to be enclosed within `---` lines
    2. The fields `name`, `project_url`, `price`, `license` should be very straightforward to fill.
    3. The field `image_tag` corresponds to the path of the image of the tool (should start with `images/guis/`).
    4. `platforms` is a list of at least 1 platform in which the tool is supported. The possibilities are: `Windows`, `Mac`, `Linux`, `Android`, and `iOS`
    5. `order` can be filled with the biggest number already existing, plus 1 (this number determines the order in which the GUIs are rendered). This is the only field whose value should _not_ be enclosed in double-quote characters.
    6. `trend_name` is an optional field that can be used for helping sorting the clients.

2. Add the image to `static/images/guis/<GUI_CLIENT_NAME>@2x.png` and `static/images/guis/<GUI_CLIENT_NAME>.png` making sure the aspect ratio matches a 588:332 image.

## Useful links

### Hugo (static site generator)

* https://gohugo.io/
* https://gohugo.io/content-management/shortcodes/
* https://github.com/google/re2/wiki/Syntax/ (for Hugo's regular expression syntax)

### Pagefind (client-side search)

* https://pagefind.app/

### Lychee (link checker)

* https://lychee.cli.rs/

### Playwright (website UI test framework)

* https://playwright.dev/

## License

The source code for the site is licensed under the MIT license, which you can find in
the MIT-LICENSE.txt file.

All graphical assets are licensed under the
[Creative Commons Attribution 3.0 Unported License](https://creativecommons.org/licenses/by/3.0/).
