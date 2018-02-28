require 'rails_helper'

RSpec.describe DocFile, type: :model do

  it { should have_many :doc_versions }

end
