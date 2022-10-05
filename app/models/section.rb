# frozen_string_literal: true

require "searchable"

# t.string      :title
# t.integer     :number
# t.string      :slug
# t.text        :plain
# t.text        :html
# t.string      :source_url
# t.belongs_to  :chapter
# t.timestamps
class Section < ApplicationRecord
  include Searchable

  default_scope { order(:number) }

  belongs_to :chapter
  has_one :book, through: :chapter
  before_save :set_slug
  after_save :index
  has_many :sections, through: :chapter
  has_many :xrefs, dependent: :delete_all

  def set_slug
    if title
      title = (chapter.title + "-" + self.title)
      title = chapter.title if self.title.empty?
      title = title.gsub(/\(|\)|\./, "").gsub(/\s+/, "-").gsub("&#39;", "-")
      self.slug = title
    end
  end

  def prev_slug
    lang = book.code
    prev_number = number - 1
    if section = sections.find_by(number: prev_number)
      return "/book/#{lang}/v#{book.edition}/#{ERB::Util.url_encode(section.slug)}"
    else
      # find previous chapter
      if ch = chapter.prev
        if section = ch.last_section
          return "/book/#{lang}/v#{book.edition}/#{ERB::Util.url_encode(section.slug)}"
        end
      end
    end

    "/book"
  end

  def next_slug
    lang = book.code
    next_number = number + 1
    if section = sections.find_by(number: next_number)
      return "/book/#{lang}/v#{book.edition}/#{ERB::Util.url_encode(section.slug)}"
    else
      if ch = chapter.next
        if section = ch.first_section
          return "/book/#{lang}/v#{book.edition}/#{ERB::Util.url_encode(section.slug)}"
        end
      end
      # find next chapter
    end

    "/book/#{lang}/v#{book.edition}"
  end

  def cs_number
    if chapter.chapter_type == "appendix"
      "A" + chapter.chapter_number.to_s + "." + number.to_s
    else
      chapter.chapter_number.to_s + "." + number.to_s
    end
  end

  def index
    client = ElasticClient.instance

    code = book.code
    begin
      client.index index: ELASTIC_SEARCH_INDEX,
                   type: "book",
                   id: "#{code}---#{slug}",
                   body: {
                     chapter: chapter.title,
                     section: title,
                     number: cs_number,
                     lang: code,
                     html: html
                   }
    rescue StandardError
      nil
    end
  end
end
