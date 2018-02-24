Fabricator(:section) do
  title "Git Section"
  slug "git-section"
  plain "Test test"
  html "<h2> Test test </h2>"
  source_url "https://git-scm.com/"
  number { sequence(:number) {|i| i } }
end
