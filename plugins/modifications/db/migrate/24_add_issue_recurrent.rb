class AddIssueRecurrent < ActiveRecord::Migration
  def self.up
		add_column  :issues, :recurrent, :boolean, :default => false, :null => false
  end
end
