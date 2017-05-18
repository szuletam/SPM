class Direction < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  safe_attributes 'name', 'initial'
  
  validates_uniqueness_of :name, :initial

	validates_presence_of :name, :initial

  has_many :issues

  scope :sorted, lambda { order("#{table_name}.name ASC") }
  
  def css_classes
		""
  end

  def to_s
		name
  end  
	
	def fullname
		"#{initial} #{name}"
	end
 
end
