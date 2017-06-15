class CreatePositions < ActiveRecord::Migration
  def change
    create_table :positions do |t|
      t.integer :position_id
      t.integer :boss_id
      t.datetime :created_on
      t.datetime :updated_on
    end

    add_column  :users,	:position_id, 	:integer
  end
end
