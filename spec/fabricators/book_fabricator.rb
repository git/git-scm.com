# frozen_string_literal: true

Fabricator(:book) do
  code "en"
  chapters(count: 3)
end
