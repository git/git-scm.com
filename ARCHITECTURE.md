# git-scm.com architecture

This document describes the general setup and architecture that runs the
git-scm.com site.

## Content

This site is served via GitHub Pages and is a [Hugo](https://gohugo.io/) site
with the search implemented using [Pagefind](https://pagefind.app/).

The content is a mix of:

  - original content from this repository

  - community book content brought in from https://github.com/progit;
    see the `lib/tasks/book2.rake` file.

  - manpages from releases of the git project, imported and formatted
    via asciidoctor; see the `lib/tasks/index.rake` task.

To deploy to GitHub Pages, it is necessary to turn off the default setting to
"publish from a branch" and instead change the setting to "publish with a
custom GitHub Actions workflow":
https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow

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
when they are imported by the GitHub workflows. Therefore, after fixing some
formatting, these workflows may need the force-rebuild flag to be toggled (see
the individual workflows for details).

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

  - code merged to `main` is auto-deployed

  - new git versions are detected daily and manual pages and download links
    updated

  - book updates (including translations) are picked up daily

There are a few tasks that still need to be handled by a human:

  - new languages for book translations need to be added to
    `script/book.rb`

  - forced re-imports of content (e.g., a formatting fix to imported
    manual pages) must be triggered manually with `force-rebuild` toggled
