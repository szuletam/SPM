class AddDirectionToUser < ActiveRecord::Migration
  def self.up
		add_column  :users,	:direction_id, 	:int,	:null => true
  end
end
