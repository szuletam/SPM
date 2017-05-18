class Topics < ActiveRecord::Migration
  def self.up
    create_table :topics, :force => true do |t|
      t.column "issue_id", :integer, :null => true
      t.column "content", :text
      t.column "created_on", :datetime, :null => true
    end
    create_table :issue_topics, :force => true do |t|
      t.column "topic_id", :integer, :null => true
      t.column "issue_id", :integer, :null => true
    end
  end

  def self.down
    drop_table :topics
    drop_table :issue_topics
  end
end
