module SummariesHelper

  def filters_for_url(manual_filters = {})
    fields = [""]
    operators = {}
    values = {}

    #se añaden los filtros de la consulta que se hizo inicialmente
    if @query && @query.filters && @query.filters.any?
      @query.filters.each do |field, filter|
        fields << field if field
        operators[field] = filter[:operator] if filter[:operator]
        if field && field == 'project_id' && filter[:values]
          projects = []
          filter[:values].each do |v|
            project = Project.find(v) rescue nil
            if project
              projects += project.self_and_descendants.map{|p| p.id.to_s }
            end
          end
          values[field] = projects
        else
          values[field] = filter[:values] if  filter[:values]
        end

      end
    end

    #se añaden los nuevos filtros de cada caso especifico y se sobreescriben si ya existian
    if manual_filters.any?
      manual_filters.each do |field, filter|
        next if (@for_direction || @for_general) && (field == 'assigned_to_id' || field == 'author_id')
        next if field == 'project_and_descendants' && (fields.include? field)
        fields << field if field && !(fields.include? field)
        operators[field] = filter[:operator] if filter[:operator]
        values[field] = filter[:values] if  filter[:values]
      end
    end

    if @for_user
      fields << "assigned_to_id" unless (fields.include? "assigned_to_id")
      operators["assigned_to_id"] = '='
      values["assigned_to_id"] = [@for_user.id]
    elsif @for_direction
      fields << "direction_id" unless (fields.include? "direction_id")
      operators["direction_id"] = '='
      values["direction_id"] = [@for_direction.id]
    end

    {"set_filter" => 1, "v" => values, "f" => fields, "op" => operators}
  end

end
