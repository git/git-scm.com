# Git Homepage

This is the web application for the [git-scm.com](http://git-scm.com) site.  It is meant to be the
first place that a person new to Git will land and download or learn about the
Git SCM system.

This app is written in Ruby on Rails and deployed on Heroku.

## Setup

You'll need a Ruby environment to run Rails.  First do:

    $ rvm use 1.9.2
    $ bundle install

Then you can populate the database with:

    


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



