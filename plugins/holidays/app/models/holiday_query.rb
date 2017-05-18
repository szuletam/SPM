# Redmine - project management software
# Copyright (C) 2006-2013  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class HolidayQuery < Query

  self.queried_class = Holiday

  self.available_columns = [
	QueryColumn.new(:id, :sortable => "#{Holiday.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true),
    QueryColumn.new(:date, :sortable => "#{Holiday.table_name}.date"),
	QueryColumn.new(:year, :sortable => "#{Holiday.table_name}.year"),
	QueryColumn.new(:description, :sortable => "#{Holiday.table_name}.description")
  ]

  def initialize(attributes=nil, *args)
    super attributes
	self.filters ||= {}
	
	self.available_columns
  end

  def initialize_available_filters
	add_available_filter "date", :type => :date
	
	add_available_filter "year", :type => :integer
  end


 
  
  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns
  end
  
  def default_columns_names
    @default_columns_names ||= [:id, :date, :year, :description]
  end

  def build_from_params(params)
    super
    self
  end

  def count(options={})
	order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)
	scope = Holiday
	
    holidays = scope.joins(([] + (options[:include] || [])).uniq).where(statement).
      order(order_option).
      limit(options[:limit]).
      offset(options[:offset]).all
	
	
    holidays.size
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end
  
  def holidays(options={})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)
	scope = Holiday
	
	order_option = order_option[0] 
	
	include = []
	
    holidays = scope.joins(([] + (options[:include] || [])).uniq).where(statement).
      order(order_option).
      limit(options[:limit]).
      offset(options[:offset]).all
    
    holidays
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end
  
end
