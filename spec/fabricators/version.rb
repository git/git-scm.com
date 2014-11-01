Fabricator(:version) do
  name { sequence(:name) {|i| "#{i}.0" } }
  commit_sha { SecureRandom.hex }
  tree_sha { SecureRandom.hex }
  committed { Time.current }
  vorder { sequence(:vorder) {|i| i } }
  downloads(count: 2)
end
