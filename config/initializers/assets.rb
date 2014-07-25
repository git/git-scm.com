# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += %w( git-scm.css modernizr.js modernizr-tests.js jquery-1.7.1.min.js jquery-ui-1.8.18.custom.min.js jquery.defaultvalue.js session.min.js site.js )
