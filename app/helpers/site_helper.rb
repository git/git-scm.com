module SiteHelper

  def highlight_no_html(high)
    strip_tags(high.to_s)
      .gsub('[highlight]', '<span class="highlight">')
      .gsub('[xhighlight]', '</span>')
  end

  def rchart(title, data, extra = nil)
    git = data[0][1]
    svn = data[1][1]
    content_tag :tr do
      content_tag(:td, title, :nowrap => true) +
      content_tag(:td, extra, :class => 'desc') +
      content_tag(:td, sprintf("%5.2f", git), :class => "number") +
      content_tag(:td, sprintf("%5.2f", svn), :class => "number") +
      content_tag(:td, "#{(svn/git).floor}x", :class => "number")
    end
  end

  def trchart(title, data, extra = nil)
    git = data[1][1]
    git2 = data[0][1]
    svn = data[2][1]

    content_tag :tr do
      content = content_tag(:td, title, :nowrap => true) + content_tag(:td, extra, :class => 'desc')
      if git2
        content += content_tag(:td, sprintf("%5.1f", git2), :class => 'number')
      else
        content += content_tag(:td)
      end
      content + content_tag(:td, sprintf("%5.1f", git)) + content_tag(:td, sprintf("%5.1f", svn))
    end
  end


  def gchart(title, data)
    labels = data.map {|v| v[0] }
    vals = data.map {|v| v[1] }
    
    v = vals.join(',')
    l = labels.join('|')

    scale = vals.max
    chart_url = "http://chart.apis.google.com/chart?"
    chart_url += "chxt=x" + "&amp;"
    chart_url += "cht=bvs" + "&amp;"
    chart_url += "chl=#{l}" + "&amp;"
    chart_url += "chd=t:#{v}" + "&amp;"
    chart_url += "chds=0,#{scale}" + "&amp;"
    chart_url += "chs=100x125" + "&amp;"
    if vals.size == 3
      chart_url += "chco=E09FA0|E09FA0|E05F49" + "&amp;"
    else
      chart_url += "chco=E09FA0|E05F49" + "&amp;"
    end
    chart_url += "chf=bg,s,fcfcfa&"
    chart_url += "chtt=#{CGI.escape(title)}"

    image_tag(chart_url.html_safe, :alt => "init benchmarks")
  end

end
