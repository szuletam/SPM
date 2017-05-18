module ChecklistsHelper

  def link_to_remove_checklist_fields(name, f, options={})
    f.hidden_field(:_destroy) + link_to(name, "javascript:void(0)", options)
  end

  def new_object(f, association)
    @new_object ||= f.object.class.reflect_on_association(association).klass.new
  end

  def fields(f, association)
    @fields ||= f.fields_for(association, new_object(f, association), :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
  end

  def new_or_show(f)
    if f.object.new_record?
      if f.object.subject.present?
        "show"
      else
        "new"
      end
    else
      "show"
    end
  end

  def done_css(f)
    if f.object.is_done
      "is-done-checklist-item"
    else
      ""
    end
  end

end
