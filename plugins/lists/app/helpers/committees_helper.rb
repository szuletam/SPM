module CommitteesHelper
  def column_content_committees(column, issue)
    value = column.value_object(issue)
    if value.is_a?(Array)
      value.collect {|v| column_value_committees(column, issue, v)}.compact.join(', ').html_safe
    else
      column_value_committees(column, issue, value)
    end
  end
  
  def column_value_committees(column, issue, value)
		if column.name == :name
			link_to issue.name, edit_committee_path(issue)
    elsif column.name == :periodicity
      l("label_#{Committee::PERIODICITIES[value]}")
    else

			format_object(value)
		end
  end
end
