class CreateUserCalendars < ActiveRecord::Migration
  def change
    create_table :user_calendars do |t|

      t.string :name

    end

    add_column(:user_calendars, :created_on, :datetime)
    add_column(:user_calendars, :updated_on, :datetime)
  end
end
