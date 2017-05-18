module HolidaysHelper
  def column_content_holidays(column, issue)
    value = column.value_object(issue)
    if value.is_a?(Array)
      value.collect {|v| column_value_holidays(column, issue, v)}.compact.join(', ').html_safe
    else
      column_value_holidays(column, issue, value)
    end
  end
  
  def column_value_holidays(column, issue, value)
	if column.name == :date
		link_to issue.date, edit_holiday_path(issue)
	else
		format_object(value)
	end
  end
end
