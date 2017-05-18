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

class ProjectQuery < Query
  
  attr_accessor :is_tree
  
  
  def is_private?
	false
  end
  
  def is_public?
	true
  end
  
  scope :visible, lambda {|*args|
    user = args.shift || User.current
    user_id = user.logged? ? user.id : 0

    where("(#{table_name}.user_id = ? )", user_id)
  }
   
  def visible?(user=User.current)
    (project.nil? || user.allowed_to?(:view_issues, project)) && (self.user_id == user.id)
  end


  self.queried_class = Project

  self.available_columns = [
	QueryColumn.new(:id, :sortable => "#{Project.table_name}.id", :default_order => 'asc', :caption => "#", :frozen => true),
    QueryColumn.new(:name, :sortable => "#{Project.table_name}.name"),
		QueryColumn.new(:identifier, :sortable => "#{Project.table_name}.identifier"),
		QueryColumn.new(:spi, :sortable => "#{Project.table_name}.spi"),
		QueryColumn.new(:cpi, :sortable => "#{Project.table_name}.cpi"),

		QueryColumn.new(:project_done_ratio, :sortable => "#{Project.table_name}.project_done_ratio"),
		QueryColumn.new(:project_start_date, :sortable => "#{Project.table_name}.project_start_date"),
		QueryColumn.new(:project_due_date, :sortable => "#{Project.table_name}.project_due_date"),
		QueryColumn.new(:project_type, :sortable => "#{Project.table_name}.project_type_id"),

		QueryColumn.new(:description, :sortable => "#{Project.table_name}.description", :inline => false),
		QueryColumn.new(:created_on, :sortable => "#{Project.table_name}.created_on"),
		QueryColumn.new(:updated_on, :sortable => "#{Project.table_name}.updated_on"),
  ]

  def initialize(attributes=nil, *args)
    super attributes
	#self.filters ||= {"status"=>{:operator=>"=", :values=>["1"]}} if User.current.admin?
	self.filters ||= {"status"=>{:operator=>"=", :values=>["1"]}}
    self.filters ||= {}
	self.is_tree = false
	self.available_columns += ProjectCustomField.visible.
								map {|cf| QueryCustomFieldColumn.new(cf) }
  end

  def initialize_available_filters
  
	if User.current.admin?
	  add_status_filter
	end
	add_available_filter "created_on", :type => :date
	
	add_available_filter "updated_on", :type => :date
		
	add_available_filter "identifier", :type => :text 
	
	add_available_filter "name", :type => :text 
	
	add_available_filter "spi", :type => :float
	add_available_filter "cpi", :type => :float
	
	add_available_filter "project_done_ratio", :type => :float
	
	add_available_filter "project_start_date", :type => :date
	add_available_filter "project_due_date", :type => :date

	add_available_filter "project_type_id",
											 :type => :list, :values => ProjectType.all.collect{|s| [s.name, s.id.to_s] }
	
	project_custom_fields = ProjectCustomField.where(:is_for_all => false)

	add_custom_fields_filters(project_custom_fields)

  end
  
  def yes_no_list
	status = Array.new
	status[0] = [1, l(:general_text_Yes)]
	status[1] = [0, l(:general_text_No)]
	status
  end

  def add_status_filter
	status = Array.new
	status[0] = [1, l(:project_status_active)]
	status[1] = [5, l(:project_status_closed)]
	status[2] = [9, l(:project_status_archived)]
	add_available_filter "status", :type => :list, :values => status.collect {|v| [v[1].to_s, v[0].to_s]}
  end
  
  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns
  end
  
  def add_extra_data
	self.available_columns += ProjectCustomField.visible.
								map {|cf| QueryCustomFieldColumn.new(cf) }
  end
  
  def default_columns_names
	@default_columns = Setting.project_list_default_columns.map(&:to_sym)
  end

  def build_from_params(params)
    super
    
    self
  end

  def count(options={})
	order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)
	scope = Project.select("DISTINCT #{Project.table_name}.id").
				joins(" LEFT JOIN #{Member.table_name} ON (#{Project.table_name}.id = #{Member.table_name}.project_id)").
				joins(" LEFT JOIN #{User.table_name} ON (#{User.table_name}.id = #{Member.table_name}.user_id)").
				where("user_id = #{User.current.id} OR #{Project.table_name}.is_public = 1")
	
	if User.current.admin?
		scope = Project
	end 
    if options[:scope] == true
	  scope = User.current.projects.active
	  if User.current.admin?
		scope = scope.active
	  end 
    end
	scope = scope.where("is_template" => 0)
	include = []
    projects = scope.where(options[:conditions]).joins((include + (options[:include] || [])).uniq).
      where(statement).
      order(order_option).
      limit(options[:limit]).
      offset(options[:offset]).all
	  
    projects.count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end
  
  def projects(options={})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)
	scope = Project.select("DISTINCT #{Project.table_name}.* ").
				joins(" LEFT JOIN #{Member.table_name} ON (#{Project.table_name}.id = #{Member.table_name}.project_id) ").
				joins(" LEFT JOIN #{User.table_name} ON (#{User.table_name}.id = #{Member.table_name}.user_id)").
				where("user_id = #{User.current.id} OR #{Project.table_name}.is_public = 1")
	if User.current.admin?
		scope = Project.select("DISTINCT #{Project.table_name}.*, CAST(CONCAT(COALESCE(projects.parent_id, projects.id), LPAD(projects.rgt, 6, '0')) AS UNSIGNED) AS column_order ")
	end 
    if options[:scope] == true
	  scope = User.current.projects.active
	  if User.current.admin?
		scope = scope.active
	  end 
    end
	scope = scope.where("is_template" => 0)
	order_option = "#{Project.table_name}.lft, " + order_option[0] if order_option[0] && order_option[0] == "projects.name ASC"
	self.is_tree = true if order_option == "#{Project.table_name}.lft, projects.name ASC" && (self.filters.size <= 1 && ! self.filters["status"].nil?)
	include = []
    projects = scope.where(options[:conditions]).joins((include + (options[:include] || [])).uniq).
      where(statement).
      order(order_option).
      limit(options[:limit]).
      offset(options[:offset]).all

	
    projects
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end
  
end
