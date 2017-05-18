class UserCalendarHour < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  safe_attributes 'due', 'init', 'total_hours', 'week_day', 'user_calendar_id'
  
  validates_presence_of :due, :init, :total_hours, :week_day
  
  validates_numericality_of :due, :only_integer => true
  
  validates_numericality_of :init, :only_integer => true
  
  validates_numericality_of :total_hours, :only_integer => true
  
  validates_numericality_of :week_day, :only_integer => true
  
  belongs_to :user_calendar, :autosave => true
  
  before_save :set_total_hours
  
  def set_total_hours 
    self.total_hours = self.due - self.init
  end
end
