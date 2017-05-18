class CreateUserCalendarHours < ActiveRecord::Migration
  def change
    create_table :user_calendar_hours do |t|

      t.integer :init

      t.integer :due

      t.integer :total_hours

      t.integer :week_day

      t.integer :user_calendar_id


    end

  end
end
