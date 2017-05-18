class CreateDirections < ActiveRecord::Migration
  def change
    create_table :directions do |t|
      t.string :name
      t.string :initial
      t.datetime :created_on
      t.datetime :updated_on
    end
  end
end
