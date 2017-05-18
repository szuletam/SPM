class AddDirectionToIssue < ActiveRecord::Migration
  def self.up
		add_column  :issues,	:direction_id, 	:int,	  :null => true
  end
end
