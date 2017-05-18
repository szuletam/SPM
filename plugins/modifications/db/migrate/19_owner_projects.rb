class OwnerProjects < ActiveRecord::Migration
  def self.up
    create_table :owner_projects, :force => true do |t|
      t.column "member_id", :integer, :null => false
      t.column "project_id", :integer, :null => false
    end
  end

  def self.down
    drop_table :owner_project
  end
end
