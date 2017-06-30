class AddDueDateIndexToUser < ActiveRecord::Migration
  def self.up
    add_index "issues", ["due_date"], name: "index_issues_on_due_date", using: :btree
  end
end
