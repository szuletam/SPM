class AddIssueSpmid < ActiveRecord::Migration
  def self.up
		add_column  :issues, :spmid, :text, :limit => 255, :null => true
  end
end
