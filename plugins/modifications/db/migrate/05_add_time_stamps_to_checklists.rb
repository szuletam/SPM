class AddTimeStampsToChecklists < ActiveRecord::Migration
  def change
    add_column :checklists, :created_at, :timestamp
    add_column :checklists, :updated_at, :timestamp
  end
end
