class AddTaskTypeToIssue < ActiveRecord::Migration
  def self.up
		add_column  :issues,	:task_type_id, 	:int,	  :null => true
  end
end
