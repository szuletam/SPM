class AddUserImportsEmail < ActiveRecord::Migration
  def self.up
    add_column  :user_imports,	:email, 	:string, :limit => 255, :null => true
  end
end