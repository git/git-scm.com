module Searchable
  extend ActiveSupport::Concern

  included do

    def self.search(keywords, options = {})

      class_name    = self.name.to_s.downcase 
      search_type   = (class_name == "section" ? "book" : "doc")
      type_name     = (search_type == "book" ? "section" : "name")
      category_name = (search_type == "book" ? "Book" : "Reference")

      query_options = {
        "size" => 10,
        "query" => {
          "bool" => {
            "should"=> [],
            "minimum_number_should_match" => 1
          },
        },
        "highlight" => {
          "pre_tags"  => ["[highlight]"],
          "post_tags" => ["[xhighlight]"],
          "fields"    => { "html" => { "fragment_size" => 200 } }
        }
      }
      lang_options = {"must" => [{ "term" => { "lang" => options[:lang] } }]}
      query_options["query"]["bool"].merge!(lang_options) if options[:lang].present?

      keywords.split(/\s|\-/).each do |keyword|
        query_options['query']['bool']['should'] << { "prefix" => { type_name => { "value" => keyword, "boost" => 12.0 } } }
        query_options['query']['bool']['should'] << { "term" => { "html" => keyword } }
      end

      search = Tire::Search::Search.new('gitscm', :type => search_type, :payload => query_options) rescue nil
      if search
        ref_hits = []
        search.results.each do |result|
          name = result.section || result.chapter || result.name
          slug = result.id.gsub('---','/')
          ref_hits << {
            :name       => name,
            :meta       => result.meta,
            :score      => result._score,
            :highlight  => result.highlight,
            :url        => (search_type == "book" ? "/book/#{slug}" : "/docs/#{name}")
          }
        end
        if ref_hits.size > 0
          return {:category => category_name, :term => keywords, :matches => ref_hits}
        end
      end

    end

  end

end
