class Committee < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  safe_attributes 'name', 'periodicity', 'initial', 'objectives', 'kpi', 'deliverable'
  
  validates_uniqueness_of :name, :initial
	validates_presence_of :name, :periodicity, :initial

  has_many :issues

  scope :sorted, lambda { order("#{table_name}.name ASC") }
  
	PERIODICITIES = {
		1 => "daily",
		2 => "weekly",
		3 => "biweekly",
		4 => "monthly",
		5 => "bimonthly",
		6 => "bimonthly_2",
		7 => "quarterly",
		8 => "biannual",
		9 => "yearly"
	}
	
  def css_classes
		""
  end

	def periodicity_name
		l("label_#{PERIODICITIES[periodicity]}")
	end

  def to_s
		name
  end  
 
end
