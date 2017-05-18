class AddCommitteesColumns < ActiveRecord::Migration
  def self.up
    add_column  :committees,	:objectives, 	:text,	  :null => true
    add_column  :committees,	:kpi, 	:text,	  :null => true
    add_column  :committees,	:deliverable, 	:text,	  :null => true
  end
end