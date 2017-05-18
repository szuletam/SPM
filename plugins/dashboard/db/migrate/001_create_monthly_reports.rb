class CreateMonthlyReports < ActiveRecord::Migration
  def change
    create_table :monthly_reports do |t|

      t.date :report_date

      t.integer :created

      t.integer :closed

      t.integer :retarded

      t.integer :direction_id


    end

  end
end
