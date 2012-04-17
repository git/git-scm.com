class DocController < ApplicationController
  layout "layout"

  def index
  end

  def ref
  end

  def test
    render 'doc/rebase'
  end

  def man
    if params[:version]
      doc_version = DocVersion.for_version(params[:file], params[:version])
    else
      doc_version = DocVersion.latest_for(params[:file])
    end

    @versions = []
    versions = DocVersion.latest_versions(params[:file])
    unchanged = []
    for i in 0..(versions.size-2)
      v = versions[i]
      prev = versions[i+1]
      sha2 = v.doc.blob_sha
      sha1 = prev.doc.blob_sha
      if sha1 == sha2
        unchanged << v.version.name
      else
        if unchanged.size > 0
          if unchanged.size == 1
            @versions << {:name => "#{unchanged.first} no changes", :changed => false}
          else
            @versions << {:name => "#{unchanged.last} &rarr; #{unchanged.first} no changes", :changed => false}
          end
          unchanged = []
        end
        @versions << {:name => v.version.name, :time => v.version.committed, :diff => Doc.get_diff(sha2, sha1), :changed => true}
      end
    end
    @versions = @versions[0,20]

    if doc_version.nil?
      redirect_to :ref
    else
      @last = DocVersion.last_changed(params[:file])
      @version = doc_version.version
      @file = doc_version.doc_file
      @doc = doc_version.doc
    end
  end

  def book
  end

  def videos
  end

  def ext
  end

end
