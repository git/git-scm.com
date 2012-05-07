# Git Homepage

This is the web application for the [git-scm.com](http://git-scm.com) site.  It is meant to be the
first place that a person new to Git will land and download or learn about the
Git SCM system.

This app is written in Ruby on Rails and deployed on Heroku.

## Setup

You'll need a Ruby environment to run Rails.  First do:

    $ rvm use 1.9.2
    $ bundle install

Then you need to create the database structure:

    $ rake db:migrate

Now you'll want to populate the man pages.  You can do so from a local Git
source clone like this:

    $ GIT_REPO=../git/.git rake local_index

Or you can do it from GitHub (much slower) like this:

    $ rake preindex

Now you need to get the latest downloads for the downloads pages:

    $ rake downloads

Now you can run the Rails site to take a look.  Specify an UPDATE_TOKEN so you
can use the world's stupidest authentication mechanism:

    $ UPDATE_TOKEN=something rails server

The site should be running on http://localhost:3000

Now you'll probably want some book data.  This is more complicated.  You'll have
to clone the progit sources, run the server and then run the populating rake
task:

    $ cd ../
    $ git clone git://github.com/progit/progit.git
    $ cd gitscm
    $ UPDATE_TOKEN=something rake genbook GITBOOK_DIR=../progit/ GENLANG=en

That will generate the book content from the markdown and post it to the Rails
server.  If you have the server running elsewhere, you can overwrite the CONTENT_SERVER
environment variable.

## Testing

To run the tests for this project, run:

    $ rake test

To run the website for testing purposes, run:

    $ bundle exec rackup config.ru

## Contributing

If you wish to contribute to this website, please fork it on GitHub, push your
change to a named branch, then send me a pull request. If it is a big feature,
you might want to contact me first to make sure it's something that I'll
accept.  If it involves code, please also write tests for it.

## License

This source code for the site is licensed under the MIT, which you can find in
the MIT-LICENSE.txt file.

All graphical assets and are licensed under the 
[Creative Commons Attribution 3.0 Unported License](http://creativecommons.org/licenses/by/3.0/).



