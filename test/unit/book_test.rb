# frozen_string_literal: true

require "test_helper"

class BookTest < ActiveSupport::TestCase

  should have_many :chapters
  should have_many(:sections).through(:chapters)

end
