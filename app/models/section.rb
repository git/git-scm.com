require 'searchable'

# t.string      :title
# t.integer     :number
# t.string      :slug
# t.text        :plain
# t.text        :html
# t.string      :source_url
# t.belongs_to  :chapter
# t.timestamps
class Section < ActiveRecord::Base

  include Searchable

  default_scope :order => 'number'

  belongs_to :chapter
  has_one :book, :through => :chapter
  before_save :set_slug
  after_save :index
  has_many :sections, :through => :chapter

  def get_related(limit = 10)
    ri = RelatedItem.where(:related_type => 'book', :related_id => slug).order('score DESC').limit(limit)
    ri.sort { |a, b| a.content_type <=> b.content_type }
  end

  def set_slug
    if self.title
      title = (self.chapter.title + '-' + self.title)
      title = self.chapter.title if self.title.empty?
      self.slug = title.gsub(' ', '-').gsub('&#39;', "'")
    end
  end

  def prev_slug
    lang = self.book.code
    prev_number = self.number - 1
    if section = self.sections.where(:number => prev_number).first
      return "/book/#{lang}/#{ERB::Util.url_encode(section.slug)}"
    else
      # find previous chapter
      if ch = self.chapter.prev
        if section = ch.last_section
          return "/book/#{lang}/#{ERB::Util.url_encode(section.slug)}"
        end
      end
    end
    '/book'
  end

  def next_slug
    lang = self.book.code
    next_number = self.number + 1
    if section = self.sections.where(:number => next_number).first
      return "/book/#{lang}/#{ERB::Util.url_encode(section.slug)}"
    else
      if ch = self.chapter.next
        if section = ch.first_section
          return "/book/#{lang}/#{ERB::Util.url_encode(section.slug)}"
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
    code = self.book.code
    data = {
      'id'        => "#{code}---#{self.slug}",
      'type'      => "book",
      'chapter'   => self.chapter.title,
      'section'   => self.title,
      'number'    => self.cs_number,
      'lang'      => code,
      'html'      => self.html,
    }
    begin
      Tire.index ELASTIC_SEARCH_INDEX do
        store data
      end
    rescue Exception => e
      nil
    end
  end

end
