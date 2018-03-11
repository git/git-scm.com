# Git Homepage [![Build Status](https://travis-ci.org/git/git-scm.com.svg?branch=master)](https://travis-ci.org/git/git-scm.com) [![Help Contribute to Open Source](https://www.codetriage.com/git/git-scm.com/badges/users.svg)](https://www.codetriage.com/git/git-scm.com)

This is the web application for the [git-scm.com](https://git-scm.com) site.  It is meant to be the
first place a person new to Git will land and download or learn about the
Git SCM system.

This app is written in Ruby on Rails and deployed on Heroku.

## Setup

You'll need a Ruby environment to run Rails.  First do:

    $ rvm use .
    $ bundle install

Then you need to create the database structure:

    $ rake db:migrate

Alternatively you can run the script at `script/bootstrap` which will set up Ruby dependencies and the local SQLite database.

Now you'll want to populate the man pages.  You can do so from a local Git
source clone like this:

    $ GIT_REPO=../git/.git rake local_index

Or you can do it from GitHub (much slower) like this:

    $ export API_USER=github_username
    $ export API_PASS=github_password
    $ rake preindex

Now you need to get the latest downloads for the downloads pages:

    $ rake downloads

Now you'll probably want some book data. You'll have
to have access to the [Pro Git project on GitHub](https://github.com/progit/progit2) through the API.

    $ export API_USER=github_username
    $ export API_PASS=github_password
    $ rake remote_genbook2

If you have 2FA enabled, you'll need to create a [Personal Access Token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/).    

That will generate the book content from the Asciidoc files fetched from the online repository and post it to the Rails server database. You can select a specific language by indicating it in the `GENLANG` environment variable:

    $ GENLANG=zh rake remote_genbook2

Alternatively, you can get the book content from a repository on your computer by specifying the path in the `GENPATH` environment variable to the `local_genbook2` target:

    $ GENLANG=fr GENPATH=../progit2-fr rake local_genbook2

Now you can run the Rails site to take a look.

    $ ./script/server

The site should be running on http://localhost:5000


## Testing

To run the tests for this project, run:

    $ rspec

To run the website for testing purposes, run:

    $ ./script/server

## Contributing

If you wish to contribute to this website, please [fork it on GitHub](https://github.com/git/git-scm.com), push your
change to a named branch, then send a pull request. If it is a big feature,
you might want to [start an issue](https://github.com/git/git-scm.com/issues/new) first to make sure it's something that will
be accepted. If it involves code, please also write tests for it.

## Adding new GUI

The [list of GUI clients](https://git-scm.com/downloads/guis) has been constructed by the community for a long time. If you want to add another tool you'll need to follow a few steps:

1. Add the GUI client details at the YAML file: https://github.com/git/git-scm.com/blob/master/resources/guis.yml
    1. The fields `name`, `url`, `price`, `license` should be very straightforward to fill.
    2. The field `image_tag` corresponds to the filename of the image of the tool (without path, just the filename).
    3. `platforms` is a list of at least 1 platform in which the tool is supported. The possibilities are: `Windows`, `Mac`, `Linux`, `Android`, and `iOS`
    4. `order` can be filled with the biggest number already existing, plus 1 (Adding to the bottom - this will be covered in the following steps)
    5. `trend_name` is an optional field that can be used for helping sorting the clients (also covered in the next steps)

2. Add the image to `public/images/guis/<GUI_CLIENT_NAME>@2x.png` and `public/images/guis/<GUI_CLIENT_NAME>.png` making sure the aspect ratio matches a 588:332 image.

3. Sort the tools
    1. From the root of the repository, run: `$ ./script/sort-gui`
    2. A list of google trends url's will be displayed at the bottom if everything went well.
    3. Open each and check if the clients are sorted.
    4. If the clients are not sorted, just fix the order (by changing the `order` field), bubbling the more 'known' clients all the way up.
    5. Repeat until the order stabilizes.
    6. It is possible that your new GUI client doesn't have good results in Google Trends. You can try similar terms (for instance, adding the git keyword sometime helps). If you find any similar term that returns better results, add the `trend_name` field to the GUI client. Have a look at the `Tower` and `Cycligent Git Tool` tools example.
    7. The script makes some basic verifications. If there was some problem, it should be easily visible in the output
      1. If you have more than 1 tool with the same name, a warning will appear: `======= WARNING: THERE ARE DUPLICATED GUIS =======`
      2. If you are using the same `order` value for more than 1 tool, a warning will appear: `======= WARNING: THERE ARE DUPLICATED ORDERS (value: <VALUE>) =======`

## License

The source code for the site is licensed under the MIT license, which you can find in
the MIT-LICENSE.txt file.

All graphical assets are licensed under the
[Creative Commons Attribution 3.0 Unported License](https://creativecommons.org/licenses/by/3.0/).
