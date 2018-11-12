# frozen_string_literal: true

module SiteHelper
  def highlight_no_html(high)
    strip_tags(high.to_s)
      .gsub("[highlight]", '<span class="highlight">')
      .gsub("[xhighlight]", "</span>")
  end

  def rchart(title, data, extra = nil)
    git = data[0][1]
    svn = data[1][1]
    out  = "<tr>"
    out += "<td nowrap>#{title}</td>"
    out += "<td class='desc'>#{extra}</td>"
    out += "<td class='number'>#{sprintf("%5.2f", git)}</td>"
    out += "<td class='number'>#{sprintf("%5.2f", svn)}</td>"
    out += "<td class='number'>#{(svn / git).floor}x</td>"
    out += "</tr>"
  end

  def trchart(title, data, extra = nil)
    git = data[1][1]
    git2 = data[0][1]
    svn = data[2][1]
    out  = "<tr>"
    out += "<td nowrap>#{title}</td>"
    out += "<td class='desc'>#{extra}</td>"
    if git2
      out += "<td class='number'>#{sprintf("%5.1f", git2)}</td>"
    else
      out += "<td></td>"
    end
    out += "<td class='number'>#{sprintf("%5.1f", git)}</td>"
    out += "<td class='number'>#{sprintf("%5.1f", svn)}</td>"
    out += "</tr>"
  end


  def gchart(title, data)
    labels = data.map { |v| v[0] }
    vals = data.map { |v| v[1] }

    v = vals.join(",")
    l = labels.join("|")

    scale = vals.max
    c = "<img src=\"https://chart.googleapis.com/chart?"
    c += "chxt=x" + "&amp;"
    c += "cht=bvs" + "&amp;"
    c += "chl=#{l}" + "&amp;"
    c += "chd=t:#{v}" + "&amp;"
    c += "chds=0,#{scale}" + "&amp;"
    c += "chs=100x125" + "&amp;"
    if vals.size == 3
      c += "chco=E09FA0|E09FA0|E05F49" + "&amp;"
    else
      c += "chco=E09FA0|E05F49" + "&amp;"
    end
    c += "chf=bg,s,fcfcfa&"
    c += "chtt=#{title}"
    c += "\" alt=\"init benchmarks\" />"
    c
  end
end
