class AddPresentedByToTopics < ActiveRecord::Migration
  def self.up
    add_column  :topics,	:presented_by, :string, :limit => 5000, :null => true
  end
end
