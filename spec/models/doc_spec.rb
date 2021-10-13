# frozen_string_literal: true

require "rails_helper"

RSpec.describe Doc, type: :model do

  it { should have_many :doc_versions }

end
