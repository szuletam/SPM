class ProjectTemplate < Project
  include Redmine::SafeAttributes
  
  safe_attributes 'is_template'
  
  default_scope { where("is_template" => true) }
  
end