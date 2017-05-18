class ProjectModulesPermissions < ActiveRecord::Migration
  def self.up
	add_column  :projects, :overview, :boolean, :null => false, :default => false
	add_column  :projects, :activity, :boolean, :null => false, :default => false
  end
end
