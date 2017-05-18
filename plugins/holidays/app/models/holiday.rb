class Holiday < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  safe_attributes 'date', 'year', 'description'
  
  validates_uniqueness_of :date
  
  validates :date, :date => true, :presence => true
  
  after_save :set_year
  
  scope :sorted, lambda { order("#{table_name}.date ASC") }
  
  def css_classes
	""
  end

  def to_s
	date
  end  
  
  def set_year
		update_column(:year, self.date.year) unless self.date.nil?
  end
  
  def self.today_is_holiday?
		exists?(:date => Time.now)
  end
  
  def self.is_holiday?(date)
		exists?(:date => date)
  end
  
  def self.between(start_date, due_date)
    where(["date BETWEEN ? AND ?", start_date , due_date])
  end
  
end
