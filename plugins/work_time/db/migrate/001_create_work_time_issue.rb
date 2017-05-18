class CreateWorkTimeIssue < ActiveRecord::Migration
  def change
    create_table :work_time_issues do |t|

      t.integer :issue_id

      t.integer :user_id

    end

  end
end
