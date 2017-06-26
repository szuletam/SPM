class AddExpirationToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :expiration_alert, :boolean, :default => false, :null => false
  end
end
