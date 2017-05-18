class CreateChecklists < ActiveRecord::Migration

  def self.up
    if ActiveRecord::Base.connection.table_exists? :issue_checklists
      rename_table :issue_checklists, :checklists
    else
      create_table :checklists do |t|
        t.boolean :is_done, :default => false
        t.string :subject
        t.integer :position, :default => 1
        t.references :issue, :null => false
      end
    end
  end

  def self.down
    drop_table :checklists
  end
end
