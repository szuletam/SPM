class CreateCommittees < ActiveRecord::Migration
  def change
    create_table :committees do |t|
      t.string :name
      t.integer :periodicity
      t.string :initial
      t.datetime :created_on
      t.datetime :updated_on
    end
  end
end
