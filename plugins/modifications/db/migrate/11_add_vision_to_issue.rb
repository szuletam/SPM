class AddVisionToIssue < ActiveRecord::Migration
  def self.up
		add_column  :issues,	:vision_id, 	:int,	  :null => true
  end
end
