class AddOriginToIssue < ActiveRecord::Migration
  def self.up
		add_column  :issues,	:origin_id, 	:int,	  :null => true
  end
end
