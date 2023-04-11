# frozen_string_literal: true

require 'fileutils'
require 'yaml'

class Book
  @@all_books = {
    "az" => "progit2-aze/progit2",
    "be" => "progit/progit2-be",
    "bg" => "progit/progit2-bg",
    "cs" => "progit-cs/progit2-cs",
    "de" => "progit/progit2-de",
    "en" => "progit/progit2",
    "es" => "progit/progit2-es",
    "fr" => "progit/progit2-fr",
    "gr" => "progit2-gr/progit2",
    "id" => "progit/progit2-id",
    "it" => "progit/progit2-it",
    "ja" => "progit/progit2-ja",
    "ko" => "progit/progit2-ko",
    "mk" => "progit2-mk/progit2",
    "ms" => "progit2-ms/progit2",
    "nl" => "progit/progit2-nl",
    "pl" => "progit2-pl/progit2-pl",
    "pt-br" => "progit/progit2-pt-br",
    "pt-pt" => "progit2-pt-pt/progit2",
    "ru" => "progit/progit2-ru",
    "sl" => "progit/progit2-sl",
    "sr" => "progit/progit2-sr",
    "tl" => "progit2-tl/progit2",
    "tr" => "progit/progit2-tr",
    "sv" => "progit2-sv/progit2",
    "uk" => "progit/progit2-uk",
    "uz" => "progit/progit2-uz",
    "zh" => "progit/progit2-zh",
    "zh-tw" => "progit/progit2-zh-tw",
    "fa" => "progit2-fa/progit2"
  }

  def self.all_books
    @@all_books
  end

  attr_accessor :chapters
  attr_accessor :sha

  def initialize(edition, language_code)
    @edition = edition
    @language_code = language_code
    @chapters = []
  end

  def front_matter
    front_matter = {
      "category" => "book",
      "section" => "documentation",
      "subsection" => "book",
      "sidebar" => "book",
      "book" => {
        "language_code" => @language_code
      }
    }
  end

  def absolute_path(path, top_level = "content")
    File.absolute_path(File.join(File.dirname(__FILE__), "..", top_level, "book", @language_code, "v#{@edition}", path))
  end

  def relative_url(path)
    return "book/#{@language_code}/v#{@edition}#{path.nil? || path.empty? || path == "." ? "" : "/#{path}"}"
  end

  def removeAllFiles
    FileUtils.rm_rf(absolute_path("."))
  end
end

class Chapter
  def initialize(book)
    @book = book
    @sections = []
    @previous_chapter = @book.chapters[-1]
    if not @previous_chapter.nil?
      @previous_chapter.next_chapter = self
    end
  end

  def front_matter
    front_matter = @book.front_matter
    front_matter["book"]["chapter"] = {
      "title" => self.title,
      "number" => self.chapter_number
    }
    return front_matter
  end

  attr_accessor :title
  attr_accessor :chapter_type
  attr_accessor :chapter_number
  attr_accessor :sha
  attr_accessor :sections
  attr_accessor :book

  def next_chapter=(chapter)
    @next_chapter = chapter
  end

  def absolute_path(path)
    return @book.absolute_path(path)
  end

  def relative_url(path)
    return @book.relative_url(path)
  end

  def previous_chapter
    return @previous_chapter
  end

  def next_chapter
    return @next_chapter
  end

  def save
    # TODO
  end
end

class Section
  def initialize(chapter, section_number)
    @chapter = chapter
    @section_number = section_number
    @previous_section = @chapter.sections[-1]
    if @previous_section.nil?
      previous_chapter = chapter.previous_chapter
      if not previous_chapter.nil?
        @previous_section = previous_chapter.sections[-1]
      end
    end
    if not @previous_section.nil?
      @previous_section.next_section = self
    end
  end

  def front_matter
    front_matter = @chapter.front_matter
    front_matter["title"] = "Git - #{self.title}"
    front_matter["book"]["section"] = {
      "title" => self.title,
      "number" => @section_number,
      "previous" => self.previous_section_url,
      "next" => self.next_section_url
    }
    return front_matter
  end

  attr_accessor :title
  attr_accessor :html
  attr_accessor :slug

  def next_section=(section)
    @next_section = section
  end

  def slug
    return @slug if not @slug.nil?
    if self.title.empty?
      title = @chapter.title
    else
      title = (@chapter.title + "-" + self.title)
    end
    @slug = title.gsub(/\(|\)|\./, "").gsub(/\s+/, "-").gsub("&#39;", "-")
  end

  def absolute_path(path)
    return @chapter.absolute_path(path)
  end

  def relative_url(path)
    return @chapter.relative_url(path)
  end

  def previous_section_url
    if @previous_section.nil?
      return self.relative_url(nil)
    end
    return self.relative_url(@previous_section.slug)
  end

  def next_section_url
    if @next_section.nil?
      return self.relative_url(nil)
    end
    return self.relative_url(@next_section.slug)
  end

  def save
    return if self.slug.nil?

    front_matter = "#{self.front_matter.to_yaml}\n---\n"

    path = self.absolute_path(self.slug)
    FileUtils.mkdir_p(File.dirname(path))
    File.open("#{path}.html", 'w') do |file|
      file.write(front_matter)
      file.write(self.html.strip)
    end
  end

  def saveImage(path, content)
    path = @chapter.book.absolute_path(path, "static")
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') do |file|
      file.write(content)
    end
  end
end
