class MemberCalendarFields < ActiveRecord::Migration
  def self.up
	add_column  :members, 	:user_calendar_id,    :integer,     :null => true
  end
end
