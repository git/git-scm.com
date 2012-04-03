require 'pp'
class SiteController < ApplicationController
  layout "layout"

  def index
  end

  def search
    query = { 'query' => params[:search] }

    query_options = {
      'bool' => {
        'must' => [
          # Search for the query across all fields
          { 'field' => { '_all' => query } },
        ]
      }
    }

    resp  = BONSAI.search( 'doc', 
                           'query' => query_options,
                           'size' => 10)

    ref_hits = []

    resp['hits']['hits'].each do |hit|
      name = hit["_source"]["name"]
      ref_hits << { 
        :name => name,
        :url  => "/doc/ref/#{name}"
      }
    end

    @data = [
      { :category => "Reference", :matches  => ref_hits }
    ]
    render :partial => 'shared/search'
  end
end
