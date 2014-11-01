class Xref < ActiveRecord::Base
  belongs_to :book
  belongs_to :section
end
