class AddDiffusedDate < ActiveRecord::Migration
  def self.up
    add_column  :issues, :diffused_date, :date, :null => true
  end
end
