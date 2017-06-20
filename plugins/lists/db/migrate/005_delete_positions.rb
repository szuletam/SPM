class DeletePositions < ActiveRecord::Migration
  def change
    drop_table :positions
    add_column  :users,	:boss_id, 	:integer
  end
end
