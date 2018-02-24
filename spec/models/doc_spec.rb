require 'spec_helper'

RSpec.describe Doc, type: :model do

  it { should have_many :doc_versions }

end
