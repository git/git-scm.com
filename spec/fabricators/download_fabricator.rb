# frozen_string_literal: true

Fabricator(:download) do
  url "http://git-scm.com/git.zip"
  filename "git.zip"
  platform "mac"
  release_date { Time.current }
end
