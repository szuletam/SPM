class AddProjectType < ActiveRecord::Migration
  def self.up
		add_column  :projects,	:project_type_id, 	:int,	  :null => true
  end
end
