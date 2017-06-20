class CreateUserImports < ActiveRecord::Migration
  def change
    create_table :user_imports do |t|
      t.string :import_key
      t.string :firstname
      t.string :lastname
      t.string :position_id
      t.string :boss_id
      t.string :username
      t.string :direction_name
      t.integer :user_id
      t.integer :row_excel
    end
  end
end
