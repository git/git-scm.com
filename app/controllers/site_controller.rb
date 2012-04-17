require 'pp'
class SiteController < ApplicationController
  layout "layout"

  def index
  end

  def admin
    @downloads = Download.all
  end

  def search
    sname = params['search'].downcase

    query_options = {
      "bool" => {
        "should" => [
            { "prefix" => { "name" => { "value" => sname, "boost" => 12.0 } } },
            { "term" => { "text" => sname } }
        ],
        "minimum_number_should_match" => 1
      }
    }

    resp  = BONSAI.search( 'doc', 
                           'query' => query_options,
                           'size' => 10)

    #pp resp
    ref_hits = []

    resp['hits']['hits'].each do |hit|
      name = hit["_source"]["name"]
      ref_hits << { 
        :name => name,
        #:meta => hit["_score"],
        :url  => "/ref/#{name}"
      }
    end

    @data = {
      :term => sname,
      :results => [{ :category => "Reference", :term => sname, :matches  => ref_hits }]
    }
    render :partial => 'shared/search'
  end
end
