require 'spec_helper'

describe Doc do

  # it { should have_many :doc_versions }


  #context "AsciiDoctor" do
    
    let(:git_diff_file_path) { Rails.root.join("spec/data/git-diff.txt").to_s }
    let(:git_diff_file) { File.read(git_diff_file_path) }

    it "parses git-diff template", focus: true do
      content = git_diff_file.gsub(/include::(.*)\.txt/, "include::\\1")
      # doc = Asciidoctor::Document.new(git_diff_file) 
      doc.source.should =~ /include::diff-options\.txt/
      # doc.render(template_dir: Rails.root.join("templates").to_s)
    end

  #end

end
