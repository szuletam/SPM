module AdvancedHelper

  def get_color_class(value, delayed = false)

    class_for_add = ''
    if (value.is_a? Numeric) && !value.to_f.nan? && value >= 0
      scale = [['vPoor', 30], ['poor', 50], ['avg', 75], ['good', 90], ['vGood', 100]]
      scale_delayed = [['vGood', 1],['vPoor', 100]]

      scale_selected = delayed ? scale_delayed: scale

      scale_selected.each do |scale_item|

        if value <= scale_item[1]
          class_for_add = scale_item[0]
          break
        end

      end

    end

    class_for_add

  end

  def filters_for_url(manual_filters = {})
    fields = [""]
    operators = {}
    values = {}

    #se añaden los nuevos filtros de cada caso especifico y se sobreescriben si ya existian
    if manual_filters.any?
      manual_filters.each do |field, filter|
        fields << field if field && !(fields.include? field)
        operators[field] = filter[:operator] if filter[:operator]
        values[field] = filter[:values] if  filter[:values]
      end
    end

    #se añaden los filtros de la consulta que se hizo inicialmente
    if @query && @query.filters && @query.filters.any?
      @query.filters.each do |field, filter|
        fields << field if field
        operators[field] = filter[:operator] if filter[:operator]
        values[field] = filter[:values] if  filter[:values]
      end
    end

    {"set_filter" => 1, "v" => values, "f" => fields, "op" => operators}
  end

  #n numero de colores que se generaran
  def get_green_to_red_scala n
    colors = []
    r = 0; g = 150; b = 0
    max = 255

    #se empieza en un g oscuro en 150 y se aclarece añadiendo g hasta 255
    #ni = numero iteraciones
    ni = (1*n/3)
    for i in 1..(1*n/3.to_f).floor
      g = 150 + (i*(max - 150)/ni.to_f).floor
      colors << rgb(r, g, b)
    end

    #una vez g esta en 255 se añade r desde 150 hasta 255 hasta llegar a amarillo
    #ni = numero iteraciones
    g = 255
    ni = 1 + (2*n/3.to_f).floor  - (1*n/3.to_f).ceil
    for j in (1*n/3.to_f).ceil..(2*n/3.to_f).floor
      i = j - (1*n/3.to_f).ceil + 1
      r = 150 + (i*(max - 150)/ni.to_f).floor
      colors << rgb(r, g, b)
    end

    #una vez g y r estan en 255 se quita g hasta 0 hasta llegar a rojo
    #ni = numero iteraciones
    g = r = 255
    ni = 1 + n - (2*n/3.to_f).ceil
    for i in (2*n/3.to_f).ceil..n
      g = ((n - i)*(max/ni.to_f)).floor
      colors << rgb(r, g, b)
    end

    #se entrega la escala de verde a rojo
    colors
  end

  end

  #n numero de colores que se generaran
  def get_red_scala n
    colors = []
    r = 255; g = 0; b = 0
    max = 255

    # se inicia la escala con el r mas fuerte y se añade g y b por igual cantidad hasta llegar al blanco
    for i in 1..n
      g = b = (i*(max/n)).round
      colors << rgb(r, g, b)
    end

    #se entrega la escala de blanco a rojo
    colors.reverse
  end

  def rgb(r, g, b)
    "##{to_hex r}#{to_hex g}#{to_hex b}"
  end

  def to_hex(n)
    n.to_s(16).rjust(2, '0').upcase
  end

  def aggregate(data, criteria)
    a = 0
    data.each { |row|
      match = 1
      criteria.each { |k, v|
        match = 0 unless (row[k].to_s == v.to_s) || (k == 'closed' &&  (v == 0 ? ['f', false] : ['t', true]).include?(row[k]))
      } unless criteria.nil?
      a = a + row["total"].to_i if match == 1
    } unless data.nil?
    a
  end

  def tab_is_direction?
    @tab == AdvancedController::TAB_DIRECTION
  end

  def tab_is_project?
    @tab == AdvancedController::TAB_PROJECT
  end

  def tab_is_users?
    @tab == AdvancedController::TAB_USERS
  end
