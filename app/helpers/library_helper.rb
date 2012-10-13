module LibraryHelper


  def version
    params[:version] || 'HEAD'
  end

  def functions_for(group)
    Function.where(:version => version, :group => group)
  end

  def all_groups
    @groups ||= Group.where(:version => version).to_a
  end

  def each_column
    columns = ['left', 'middle', 'right']
    total_entries = all_groups.map{|g| g.functions.length}.inject(:+) || 0
    total_groups = all_groups.length

    columns.each do |col_class|
      entries = 0
      yield(col_class, all_groups.last(total_groups).take_while { |g|
        total_groups -= 1
        entries += g.functions.length 
        entries < (total_entries / 3)
      })
    end
  end

  def function_nav_link(name, count)
    link_to "#{api_route}/g/#{name}", {:class => (@subsection == name) ? 'active' : ''} do
      content_tag(:span, name) + content_tag(:em, "(#{count})")
    end
  end

  def type_link(name)
    link_to name, "#" 
  end

  def api_route
    version == 'HEAD' ? '/library/api' : '/library/api/' + version
  end

  def function_link(function)
    link_to function.name, "#{api_route}/f/#{function.name}"
  end

  def markdown(text)
    return "" unless text
    Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(text).html_safe
  end
end
