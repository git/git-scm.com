module SiteHelper
  def highlight_no_html(high)
    strip_tags(high.to_s)
      .gsub('[highlight]', '<span class="highlight">')
      .gsub('[xhighlight]', '</span>')
  end
end
