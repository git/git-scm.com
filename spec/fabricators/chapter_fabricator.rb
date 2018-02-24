Fabricator(:chapter) do
  title "Git"
  number { sequence(:number) {|i| i } }
  sha { SecureRandom.hex }
  sections(count: 3)
end
