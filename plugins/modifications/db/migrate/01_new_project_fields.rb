class NewProjectFields < ActiveRecord::Migration
  def self.up
	add_column  :projects, 	   	:is_template, 			:boolean,  	:null => true, 		:default => 0
	add_column  :projects, 	   	:cpi, 					:float,  				:null => true, 	:default => 0
	add_column  :projects, 	   	:spi, 					:float,  				:null => true, 	:default => 0
  end
end
