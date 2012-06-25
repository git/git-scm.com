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
    if defined?(BONSAI)
      code = self.chapter.book.code
      data = {
        'chapter' => self.chapter.title,
        'section' => self.title,
        'number' => self.cs_number,
        'lang' => code,
        'html' => self.html,
      }
      id = "#{code}---#{self.slug}"
      BONSAI.add 'book', id, data
    end
  rescue Object => e
    require 'pp'
    pp e
    nil  # this is busted in production for some reason, which is really an issue
  end

  def self.search(term, lang = 'en', highlight = false)
    query_options = {
      "bool" => {
        "must" => [
            { "term" => { "lang" => lang } }
        ],
        "should" => [],
        "minimum_number_should_match" => 1
      }
    }

    terms = term.split(/\s|-/)
    terms.each do |terma|
      query_options['bool']['should'] << { "prefix" => { "section" => { "value" => terma, "boost" => 12.0 } } }
      query_options['bool']['should'] << { "term" => { "html" => terma } }
    end

    highlight_options = {
      'pre_tags'  => ['[highlight]'],
      'post_tags' => ['[xhighlight]'],
      'fields'    => { 'html' => {"fragment_size" => 200} }
    }

    options = { 'query' => query_options,
                'size' => 10 }
    options['highlight'] = highlight_options

    resp  = BONSAI.search('book', options)

    ref_hits = []
    resp['hits']['hits'].each do |hit|
      name = hit["_source"]["section"]
      name = hit["_source"]["chapter"] if name.empty?
      slug = hit["_id"].gsub('---', '/')
      lang = hit["_source"]["lang"]
      meta = "Chapter " + hit["_source"]['number'] + ' : ' + hit["_source"]["chapter"]
      highlight = hit.has_key?('highlight') ? hit['highlight']['html'].first : nil
      ref_hits << { 
        :name => name,
        :meta => meta,
        :score => hit["_score"],
        :highlight => highlight,
        :url  => "/book/#{slug}"
      }
    end

    if ref_hits.size > 0
      return { :category => "Book", :term => term, :matches  => ref_hits }
    else
      nil
    end

  end

end
