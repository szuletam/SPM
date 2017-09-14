class AddIssueConfidentiality < ActiveRecord::Migration
	def self.up
    add_column :issues, :confidentiality_id, :string
  end
end