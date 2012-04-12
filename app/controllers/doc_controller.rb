class DocController < ApplicationController
  layout "layout"

  def index
  end

  def ref
  end

  def man
    if params[:version]
      doc_version = DocVersion.for_version(params[:file], params[:version])
    else
      doc_version = DocVersion.latest_for(params[:file])
    end

    @versions = []
    versions = DocVersion.latest_versions(params[:file])
    for i in 0..(versions.size-2)
      v = versions[i]
      prev = versions[i+1]
      sha2 = v.doc.blob_sha
      sha1 = prev.doc.blob_sha
      @versions << {:name => v.version.name, :time => v.version.committed, :changed => (sha1 == sha2)}
    end

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
