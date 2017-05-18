filepath = 'LUA2016VF.csv'
settings = {"separator"=>",", "wrapper"=>'"', "encoding"=>"UTF-8", "date_format"=>"%Y-%m-%d"}

statuses = {'Abierta' => 1, 'Cerrada' => 8}
csv_options = {:headers => false}
csv_options[:encoding] = settings['encoding'].to_s.presence || 'UTF-8'
separator = settings['separator'].to_s
csv_options[:col_sep] = separator if separator.size == 1
wrapper = settings['wrapper'].to_s
csv_options[:quote_char] = wrapper if wrapper.size == 1

first = true
headers = []
data = []
CSV.foreach(filepath, csv_options) do |row|
  if !first
    zipped = headers.zip(row)
    data <<  Hash[zipped]
  else
    headers = row
    first = false
  end
end

k = 2
data.each do |id|
  i = Issue.find_by(:subject => id['TAREA'])
  if i.nil?
    puts "#{k}: #{id['TAREA']} no existe"
  else
    if i.start_date.to_s == id['FECHA INICIO'] && i.origin.name == id['ORIGEN']
      change = false
      if i.status.name != id['ESTADO']
        change = true
        i.status_id = statuses[id['ESTADO']]
      end

      if i.due_date.to_s != id['PLAZO D M A']
        change = true
        i.due_date = (Date.strptime(id['PLAZO D M A'], settings["date_format"]) rescue nil)
      end
      if i.description != id['NOTAS']
        change = true
        i.description = id['NOTAS']
      end

      i.save if change
      puts "#{k}:#{i.id.to_s} actualizado" if change
      puts "#{k}:#{i.id.to_s} no fue actualizado" unless change

    end
  end
  k = k + 1
end
