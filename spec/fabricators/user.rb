Fabricator(:user) do
  github_id { sequence(:github_id) {|i| (i * 100).to_s } }
  screen_name { sequence(:github_user_name) {|x| "test-#{x}" } }
end
