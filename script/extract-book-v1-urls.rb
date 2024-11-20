#!/usr/bin/ruby

require "open-uri"
require 'uri'
require 'yaml'

# This global variable holds a list corresponding to all ProGit v1 chapters
# (which start at chapter 1, i.e. `$v1_to_v2[4]` corresponds to chapter 4,
# that's why `$v1_to_v2[0]` is `nil`).
#
# The entry for each chapter, is a list corresponding to each section (again,
# starting at 1, that's why the the first item is `nil`) whose value is the
# "cs_number" (i.e. `<chapter>.<section>`) of the _ProGit v2_ book to which
# it should map.
$v1_to_v2 = [
  nil,
  [nil, "1.1", "1.2", "1.3", "1.5", "1.6", "1.7", "1.8"],
  [nil, "2.1", "2.2", "2.3", "2.4", "2.5", "2.6", "2.7", "2.8"],
  [nil, "3.1", "3.2", "3.3", "3.4", "3.5", "3.6", "3.7"],
  [nil, "4.1", "4.2", "4.3", "4.4", "4.9", "4.9", "4.9", "4.9", "4.5", "4.9", "4.10"],
  [nil, "5.1", "5.2", "5.3", "5.4"],
  [nil, "7.1", "7.2", "7.3", "7.6", "7.10", "7.11", "7.8", "7.15"],
  [nil, "8.1", "8.2", "8.3", "8.4", "8.5"],
  [nil, "9.1", "9.2", "9.3"],
  [nil, "10.1", "10.2", "10.3", "10.4", "10.5", "10.6", "10.7", "10.9"]
]

$mapping = {}
$translations = []

def retrieve_mapping(language)
  puts "Retrieving TOC for #{language}"
  cached = "cached.book-toc.#{language}.html"
  if File.exists?(cached)
    html = File.read(cached)
  else
    html = URI.parse("https://web.archive.org/web/20140109005424/http://git-scm.com/book/#{language}/").read
    File.write(cached, html)
  end
  lines = html.split("\n")

  # parse translations
  if language == "en"
    skip = true
    lines.each do |line|
      if skip
        skip = false if line.include? "This book is translated into"
      elsif line =~ /<a href="[^"]*\/([^"]+)">/
        $translations << $1
      elsif line.include?("<hr")
        skip = true
      end
    end
  end

  # parse chapters and sections
  $mapping[language] = {}

  skip = true
  cs_number = ""
  lines.each do |line|
    if skip
      skip = false if line.include?("<ol class=\"book-toc\">")
    else
      if line.include?("</div>")
        skip = true
      else
        if line =~ /<h2>(\d+)\./
          # map v1 to v2
          cs_number = $v1_to_v2[$1.to_i][1]
        elsif line =~ /^\s*(\d+\.\d+)\s*$/
          chapter_v1, section_v1 = $1.split(".")
          # map v1 to v2
          cs_number = $v1_to_v2[chapter_v1.to_i][section_v1.to_i]
        elsif line =~ />Index of Commands</
          cs_number = "A3.1"
        end

        if line =~ /<a href="[^"]*:\/\/git-scm.com\/book\/(?:[^"\/]+\/)?([^"\/]+)"/
          $mapping[language][cs_number] = [] if $mapping[language][cs_number].nil?
          $mapping[language][cs_number] << URI.decode_www_form_component($1, enc="utf-8")
        end
      end
    end
  end
end

retrieve_mapping "en"
$translations.each { |language| retrieve_mapping language }
File.write("data/book_v1.yml", $mapping.to_yaml)
