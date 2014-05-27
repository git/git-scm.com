Fabricator(:doc) do
  blob_sha { SecureRandom.hex }
  plain "git-file"
  html "<html>git-file</html>"
end


 => #<Doc id: 3719, blob_sha: "e5a3c9fea7809621c5e923e8ac47482b8bc7c304", plain: "git-merge(1)\n============\n\nNAME\n----\ngit-merge - Jo...", html: "<div class='man-page'>\n  <div id=\"header\">\n    <h1>...", created_at: "2014-05-06 00:37:34", updated_at: "2014-05-06 00:37:34">
