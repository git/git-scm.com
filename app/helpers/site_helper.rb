module SiteHelper
  def highlight_no_html(high)
    strip_tags(high.to_s)
      .gsub('[highlight]', '<span class="highlight">')
      .gsub('[xhighlight]', '</span>')
  end

  def gchart(title, data)
    labels = data.map {|v| v[0] }
    vals = data.map {|v| v[1] }
    
    v = vals.join(',')
    l = labels.join('|')

    scale = vals.max
    c = "<img src=\"http://chart.apis.google.com/chart?"
    c += "chxt=x" + "&amp;"
    c += "cht=bvs" + "&amp;"
    c += "chl=#{l}" + "&amp;"
    c += "chd=t:#{v}" + "&amp;"
    c += "chds=0,#{scale}" + "&amp;"
    c += "chs=100x125" + "&amp;"
    if vals.size == 3
      c += "chco=009099|009099|E05F49" + "&amp;"
    else
      c += "chco=009099|E05F49" + "&amp;"
    end
    c += "chf=bg,s,fcfcfa&"
    c += "chtt=#{title}"
    c += "\" alt=\"init benchmarks\" />"
    c
  end
end
