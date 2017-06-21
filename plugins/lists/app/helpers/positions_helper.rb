module PositionsHelper
  def column_content_positions(column, issue)
    value = column.value_object(issue)
    if value.is_a?(Array)
      value.collect {|v| column_value_positions(column, issue, v)}.compact.join(', ').html_safe
    else
      column_value_positions(column, issue, value)
    end
  end
  
  def column_value_positions(column, issue, value)
		if column.name == :position_id
			link_to issue.position_id, edit_position_path(issue)
		else
			format_object(value)
		end
  end
end
