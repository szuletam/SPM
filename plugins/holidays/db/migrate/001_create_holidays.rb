class CreateHolidays < ActiveRecord::Migration
  def change
    create_table :holidays do |t|
      t.date :date
      t.text :description
	  t.integer :year
      t.datetime :created_on
      t.datetime :updated_on
    end
  end
end
