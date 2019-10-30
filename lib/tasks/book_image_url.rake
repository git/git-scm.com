# frozen_string_literal: true
desc "Check Book Image URLs"
task :book_image_url do
  require "net/http"
  File.open(File.join(Rails.root, "app", "views", "doc", "_ext_books.erb")).each { |line|
    # Check every img element to ensuer the src attribute is valid
    if ((match = line.match(/.*<img\ssrc="([http|https].*)">/)))
      url = URI.parse(match[1])
      req = Net::HTTP.new(url.host, url.port)
      req.use_ssl = match[1].start_with?("https")
      res = req.request_head(url.path)

      if res.code.to_i == 404
        puts "[WARN] A book image specified at the following URL was not found: #{match[1]}"
      end
    end
  }
end
