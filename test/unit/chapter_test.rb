# frozen_string_literal: true

require "test_helper"

class ChapterTest < ActiveSupport::TestCase

  should belong_to :book
  should have_many :sections

end
