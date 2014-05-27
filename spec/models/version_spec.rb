require 'spec_helper'

describe Version do

  it { should have_many :doc_versions }
  it { should have_many(:docs).through(:doc_versions) }
  it { should have_many :downloads }
  it { should validate_uniqueness_of :name }

  it "compares versions" do
    v1 = Version.version_to_num("1.0.0")
    v2 = Version.version_to_num("1.7.10")
    v3 = Version.version_to_num("1.8.0.1")
    (v1 < v2).should be_true
    (v2 < v3).should be_true
  end


end
