# frozen_string_literal: true

require "test_helper"

class SectionTest < ActiveSupport::TestCase

  should belong_to :chapter
  should have_one(:book).through(:chapter)

end
