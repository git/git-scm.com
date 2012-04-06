require 'pp'
class SiteController < ApplicationController
  layout "layout"

  def index
  end

  def search
    query_options = {
      'prefix' => {
        'name' => params['search'].downcase
      }
    }

    p query_options

    resp  = BONSAI.search( 'doc', 
                           'query' => query_options,
                           'size' => 10)

    p resp
    ref_hits = []

    resp['hits']['hits'].each do |hit|
      name = hit["_source"]["name"]
      ref_hits << { 
        :name => name,
        :url  => "/ref/#{name}"
      }
    end

    @data = [
      { :category => "Reference", :matches  => ref_hits }
    ]
    render :partial => 'shared/search'
  end
end
