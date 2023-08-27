# git-scm.com architecture

This document describes the general setup and architecture that runs the
git-scm.com site.

## Content

This site is served via GitHub Pages and is a [Hugo](https://gohugo.io/) site
with the search implemented using [Pagefind](https://pagefind.app/).

The content is a mix of:

  - original content from this repository

  - community book content brought in from https://github.com/progit;
    see the `script/update-book2.rb` and `script/book.rb` files.

    The content is pre-rendered and tracked in the `external/book/` directory
    tree.

  - manual pages from releases of the git project, imported and formatted via
    AsciiDoctor, and translated versions of the manual pages from
    https://github.com/jnavila/git-manpages-l10n/ (which itself contains
    pre-rendered pages from https://github.com/jnavila/git-manpages-l10n/); see
    the `script/update-docs.rb` file.

    The pre-rendered pages are tracked in the `external/docs/` directory tree.

To deploy to GitHub Pages, it is necessary to turn off the default setting to
"publish from a branch" and instead change the setting to "publish with a
custom GitHub Actions workflow":
https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow
With this change, the site can be tested in the fork by pushing to the
`gh-pages` branch (which will trigger the `deploy.yml` workflow) and then
navigating to https://git-scm.<user>.github.io/.

## Non-static parts

While the site consists mostly of static content, there are a couple of
parts that are sort of dynamic.

The search is implemented client-side, via [Pagefind](https://pagefind.app/).

A few scheduled GitHub workflows keep the content up to date:

  - `update-git-version-and-manual-pages` and `update-download-data` (pick
    up newly released git versions)

  - `update-translated-manual-pages` (fetch and format translated manual
    pages from the jnavila/git-html-l10n repository)

  - `update-book` (fetch and format progit2 book content,
    including translations)

These workflows are also marked as `workflow_dispatch`, i.e. they can be run
manually (e.g. to update the download links just after Git for Windows
published a new release).

Merges to the `gh-pages` branch on GitHub auto-deploy to GitHub Pages via the
`deploy` GitHub workflow.

Note that some of the formatting of manual pages and book content happens
when they are imported by the GitHub workflows. Therefore, whenever there are
changes to the scripts/workflows/automation that affect formatting, these
workflows may need to be triggered using the force-rebuild flag to be toggled
(see the individual workflows for details).

## DNS

The actual DNS service is provided by Cloudflare. The domain itself is
registered with Gandi, and is owned by the project via Software Freedom
Conservancy. Funds for the registration are provided from the Git project's
Conservancy funds, and both the Git PLC and Conservancy have credentials to
modify the setup.

Note that we own both git-scm.com and git-scm.org; the latter redirects
to the former.

## Manual Intervention

The site mostly just runs without intervention:

  - code merged to `gh-pages` is auto-deployed

  - new git versions are detected daily and manual pages and download links
    updated

  - book updates (including translations) are picked up daily

There are a few tasks that still need to be handled by a human:

  - new languages for book translations need to be added to
    `script/book.rb`

  - forced re-imports of content (e.g., when fixing formatting in the
    imported manual pages) must be triggered manually with `force-rebuild`
    toggled
