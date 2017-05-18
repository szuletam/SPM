class AddOthersForCommittee < ActiveRecord::Migration
  def self.up
    add_column  :issues,	:others, :string, :limit => 5000, :null => true
  end
end
