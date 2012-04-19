# t.string      :title
# t.integer     :number
# t.string      :slug
# t.text        :plain
# t.text        :html
# t.string      :source_url
# t.belongs_to  :chapter
# t.timestamps
class Section < ActiveRecord::Base
  default_scope :order => 'number'

  belongs_to :chapter
  has_one :book, :through => :chapter
  before_save :set_slug
  after_save :index

  def set_slug
    if self.title
      self.slug = (self.chapter.title + '-' + self.title).gsub(' ', '-')
    end
  end

  def prev_slug
    lang = self.book.code
    prev_number = self.number - 1
    if section = self.chapter.sections.where(:number => prev_number).first
      return "/book/#{lang}/#{section.slug}"
    else
      # find previous chapter
      if ch = self.chapter.prev
        if section = ch.last_section
          return "/book/#{lang}/#{section.slug}"
        end
      end
    end
    '/book'
  end

  def next_slug
    lang = self.book.code
    next_number = self.number + 1
    if section = self.chapter.sections.where(:number => next_number).first
      return "/book/#{lang}/#{section.slug}"
    else
      if ch = self.chapter.next
        if section = ch.first_section
          return "/book/#{lang}/#{section.slug}"
        end
      end
      # find next chapter
    end
    "/book/#{lang}"
  end

  def cs_number
    self.chapter.number.to_s + '.' + self.number.to_s
  end

  def index
    if BONSAI
      data = {
        'chapter' => self.chapter.title,
        'section' => self.title,
        'number' => self.cs_number,
        'lang' => self.chapter.book.code,
        'html' => self.html,
      }
      BONSAI.add 'book', self.slug, data
    end
  rescue Object => e
    require 'pp'
    pp e
    nil  # this is busted in production for some reason, which is really an issue
  end

  def self.search(term)
    query_options = {
      "bool" => {
        "should" => [
            { "prefix" => { "section" => { "value" => term, "boost" => 12.0 } } },
            { "term" => { "html" => term } }
        ],
        "minimum_number_should_match" => 1
      }
    }

    resp  = BONSAI.search('book',
                          'query' => query_options,
                          'size' => 10)

    ref_hits = []
    resp['hits']['hits'].each do |hit|
      name = hit["_source"]["section"]
      name = hit["_source"]["chapter"] if name.empty?
      slug = hit["_id"]
      lang = hit["_source"]["lang"]
      meta = "Chapter " + hit["_source"]['number'] + ' : ' + hit["_source"]["chapter"]
      ref_hits << { 
        :name => name,
        :meta => meta,
        :url  => "/book/#{lang}/#{slug}"
      }
    end

    if ref_hits.size > 0
      return { :category => "Book", :term => term, :matches  => ref_hits }
    else
      nil
    end

  end

end
