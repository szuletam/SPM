class AddDetailToTopics < ActiveRecord::Migration
  def self.up
    add_column  :topics,	:detail, :string, :limit => 5000, :null => true
  end
end
