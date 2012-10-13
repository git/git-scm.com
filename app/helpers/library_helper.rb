module LibraryHelper
  def functions_for(group)
    Function.where(:group => group)
  end

  def each_group(&block)
    @groups.each(&block)
  end

  def each_column
    columns = ['left', 'middle', 'right']
    total_entries = @groups.map{|g| g.functions.length}.inject(:+) || 0
    total_groups = @groups.length

    columns.each do |col_class|
      entries = 0
      yield(col_class, @groups.last(total_groups).take_while { |g|
        total_groups -= 1
        entries += g.functions.length 
        entries < (total_entries / 3)
      })
    end
  end

  def function_nav_link(name, count)
    link_to "#", {:class => (@subsection == name) ? 'active' : ''} do
      content_tag(:span, name) + content_tag(:em, "(#{count})")
    end
  end
end
