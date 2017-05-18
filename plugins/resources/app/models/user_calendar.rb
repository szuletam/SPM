class UserCalendar < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  safe_attributes 'name'
  
  validates_presence_of :name
  
  has_many :user_calendar_hours, :dependent => :destroy
  
  validate :hours_numbers
  
  def hours_numbers
    errors.add(:base, l(:error_user_calendar_hours)) unless user_calendar_hours.any?
  end
  
  def self.default
    UserCalendar.find(Setting.default_calendar) rescue nil
  end
  
  def to_s
	self.name
  end
  
end
