class AddDirectorToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :director, :boolean, :default => false, :null => false
    add_column :users, :general, :boolean, :default => false, :null => false
  end
end
