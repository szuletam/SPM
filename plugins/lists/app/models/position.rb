class Position < ActiveRecord::Base
  include Redmine::SafeAttributes
  
  safe_attributes 'boss_id', 'position_id'

  validates_presence_of :position_id
  validates_numericality_of :position_id, :boss_id, :only_integer => true

  belongs_to :parent, :class_name => 'Position', :foreign_key => 'boss_id', :primary_key => 'position_id', :inverse_of => :children
  has_many :children, :class_name => 'Position', :foreign_key => 'boss_id', :primary_key => 'position_id', :inverse_of => :parent
  has_one :user,:class_name => 'User', :primary_key => 'position_id', :foreign_key => 'position_id'

  scope :roots, lambda {
    where("boss_id IS NULL")
  }

  scope :sorted, lambda { order("#{table_name}.position_id ASC") }

  send :include, ActiveRecord::Acts::Tree::InstanceMethods
end
