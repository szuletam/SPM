module DirectionsHelper
  def column_content_directions(column, issue)
    value = column.value_object(issue)
    if value.is_a?(Array)
      value.collect {|v| column_value_directions(column, issue, v)}.compact.join(', ').html_safe
    else
      column_value_directions(column, issue, value)
    end
  end
  
  def column_value_directions(column, issue, value)
		if column.name == :name
			link_to issue.name, edit_direction_path(issue)
		else
			format_object(value)
		end
  end
end
