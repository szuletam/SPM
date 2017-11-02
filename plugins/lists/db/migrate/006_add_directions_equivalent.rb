class AddDirectionsEquivalent < ActiveRecord::Migration
  def self.up
    add_column  :directions,	:equivalent, 	:string, :limit => 255, :null => true
  end
end