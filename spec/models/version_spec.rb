# frozen_string_literal: true

require "rails_helper"

RSpec.describe Version, type: :model do

  it { should have_many :doc_versions }
  it { should have_many(:docs).through(:doc_versions) }
  it { should have_many :downloads }
  it { should validate_uniqueness_of :name }

  it "compares versions" do
    v1 = Version.version_to_num("1.0.0")
    v2 = Version.version_to_num("1.7.10")
    v3 = Version.version_to_num("1.8.0.1")
    expect(v1).to be < v2
    expect(v2).to be < v3
  end


end
