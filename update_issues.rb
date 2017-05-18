tasks = Issue.where(:tracker_id => Setting.default_application_for_task.to_i)
ams = []
tasks.each do |task|
    act = task.parent
    if act.nil?
        puts "la tarea #{task.id} no tiene acta"
        ams << task
    else
        committee = act.project
        if committee.nil?
            puts "el acta #{act.id} que contiene la tarea #{task.id} no está asociado a un projecto"
            ams << task
        else
            project = committee.parent
            if committee.nil?
                puts "el proyecto #{committee.id} que tiene el acta #{act.id} que contiene la tarea #{task.id} no tiene proyecto padre"
                ams << task
            else
                strategies = []
                strategies = project.descendants.map{|s| [s.id, s]}.to_h if project.descendants
                if strategies.nil? || !strategies.keys.any?
                    puts "no hay ejes estrategicos para el proyecto #{committee.id} que tiene el acta #{act.id} que contiene la tarea #{task.id} no tiene proyecto padre"
                    ams << task
                else
                    unless strategies.keys.include? task.project.id
                        good_project = strategies[strategies.map{|id, p| [id, p.name]}.to_h.key(task.project.name)]
                        task.project = good_project
                        if task.save
                            puts "#la tarea #{task.id} fue actualizada"
                        else
                            puts "#la tarea #{task.id} no pudo ser actualizada"
                        end
                        ams << task
                    end
                end
            end
        end
    end
end

puts "hay #{ams.length} tareas mal asignadas"