# Git Homepage [![Build Status](https://travis-ci.org/git/git-scm.com.png?branch=master)](https://travis-ci.org/git/git-scm.com)

This is the web application for the [git-scm.com](http://git-scm.com) site.  It is meant to be the
first place a person new to Git will land and download or learn about the
Git SCM system.

This app is written in Ruby on Rails and deployed on Heroku.

## Setup

You'll need a Ruby environment to run Rails.  First do:

    $ rvm use 2.1.8
    $ bundle install

Then you need to create the database structure:

    $ rake db:migrate

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
to have access to the [Pro Git project on GitHub](https://github.com/progit/progit) through the API.

    $ export API_USER=github_username
    $ export API_PASS=github_password
    $ rake remote_genbook

That will generate the book content from the Markdown files fetched from the online repository and post it to the Rails server database.

Now you can run the Rails site to take a look.  Specify an UPDATE_TOKEN so you
can use the world's stupidest authentication mechanism:

    $ UPDATE_TOKEN=something rails server

The site should be running on http://localhost:3000


## Testing

To run the tests for this project, run:

    $ rspec

To run the website for testing purposes, run:

    $ rails server

## Contributing

If you wish to contribute to this website, please [fork it on GitHub](https://github.com/git/git-scm.com), push your
change to a named branch, then send a pull request. If it is a big feature,
you might want to start an Issue first to make sure it's something that will
be accepted.  If it involves code, please also write tests for it.

## License

The source code for the site is licensed under the MIT license, which you can find in
the MIT-LICENSE.txt file.

All graphical assets are licensed under the
[Creative Commons Attribution 3.0 Unported License](http://creativecommons.org/licenses/by/3.0/).
