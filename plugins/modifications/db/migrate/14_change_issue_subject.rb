class ChangeIssueSubject < ActiveRecord::Migration
  def self.up
    change_column :issues, :subject, :string, :limit => 5000
  end
end
