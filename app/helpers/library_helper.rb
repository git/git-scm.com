module LibraryHelper
  def version
    params[:version] || 'HEAD'
  end

  def all_versions
    if @versions.nil?
      @versions = Library.versions.sort
      
      # Natural sort, baby
      @versions.sort! { |a, b|
        if a == 'HEAD' then -1
        elsif b == 'HEAD' then 1
        else a[1..-1].split('.').map(&:to_i) <=> b[1..-1].split('.').map(&:to_i)
        end
      }
    end
    @versions
  end

  def all_groups
    @groups ||= Group.all(version)
  end

  def each_column
    columns = ['left', 'right']
    total_entries = all_groups.map{|g| g.size}.inject(:+) || 0
    total_groups = all_groups.length

    columns.each do |col_class|
      entries = 0
      yield(col_class, all_groups.last(total_groups).take_while { |g|
        total_groups -= 1
        entries += g.size
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
    '/library/api/' + version
  end

  def group_link(group)
    link_to group.name, "#{api_route}/g/#{group.name}"
  end

  def function_link(function)
    link_to function, "#{api_route}/f/#{function}", {:class => Random.rand(3) == 1 ? 'important' : ''}
  end

  def markdown(text)
    return "" unless text
    Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(text).html_safe
  end
end
