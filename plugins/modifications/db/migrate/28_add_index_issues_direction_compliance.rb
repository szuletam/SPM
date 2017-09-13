class AddIndexIssuesDirectionCompliance < ActiveRecord::Migration
	def change
    add_index :issues, :direction_id
    add_index :issues, :compliance_date
  end
end