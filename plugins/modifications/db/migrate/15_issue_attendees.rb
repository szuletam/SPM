class IssueAttendees < ActiveRecord::Migration
  def self.up
    create_table :issue_attendants, :force => true do |t|
      t.column "issue_id", :integer, :null => true
      t.column "user_id", :text
      t.column "created_on", :datetime, :null => true
      t.column "invited", :bool, :null => true

    end
  end
end
