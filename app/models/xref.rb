# frozen_string_literal: true

class Xref < ApplicationRecord
  belongs_to :book
  belongs_to :section
end
