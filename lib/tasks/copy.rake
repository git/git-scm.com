task :copy do
  puts "copying images"
  `cp -Rf ../scm-mock/source/images/* public/images/`
  puts "copying styles"
  `cp -Rf ../scm-mock/source/stylesheets/* app/assets/stylesheets/`
  puts "copying js"
  `cp -Rf ../scm-mock/source/javascripts/* app/assets/javascripts/`
  puts 'copying layouts'
  `cp ../scm-mock/source/layout.haml app/views/layouts/layout.html.haml`
  `cp ../scm-mock/source/index.html.haml app/views/site/`
  `cp ../scm-mock/source/shared/_* app/views/shared/`
end
