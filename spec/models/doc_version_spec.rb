require 'spec_helper'

describe DocVersion do

  it { should belong_to :doc }
  it { should belong_to :version }
  it { should belong_to :doc_file }

  it 'finds most recent version' do
    range = 0..3
    file = Fabricate(:doc_file, :name => 'test-command')
    docs = range.map{|i| Fabricate(:doc, :plain => "Doc #{i}")}
    vers = range.map{|i| Fabricate(:version, :name => "#{i}.0", :vorder => Version.version_to_num("#{i}.0"))}
    dver = range.map{|i| Fabricate(:doc_version, :doc_file => file, :version => vers[i], :doc => docs[i])}
    dv = DocVersion.latest_for('test-command')
    docs[3].should == dv.doc
  end

  it 'finds a specific version' do
    range = 0..3
    file = Fabricate(:doc_file, :name => 'test-command')
    docs = range.map{|i| Fabricate(:doc, :plain => "Doc #{i}")}
    vers = range.map{|i| Fabricate(:version, :name => "v#{i}.0")}
    dver = range.map{|i| Fabricate(:doc_version, :doc_file => file, :version => vers[i], :doc => docs[i])}

    dv = DocVersion.for_version('test-command', 'v2.0')
    docs[2].should == dv.doc
  end
end
