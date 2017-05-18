class AddComplianceDateToIssue < ActiveRecord::Migration
  def self.up
		add_column  :issues,	:compliance_date, 	:date,	  :null => true
  end
end
