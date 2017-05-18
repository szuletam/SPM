class ProjectSpentFields < ActiveRecord::Migration
  def self.up
	add_column  :projects, 	   	:project_start_date,    :date,     	:null => true
	add_column  :projects, 	   	:project_due_date,    	:date,     	:null => true
	add_column  :projects, 	   	:project_done_ratio, 	:integer,  		:null => true, 	:default => 0
  end
end
