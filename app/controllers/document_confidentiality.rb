class DocumentConfidentiality < Enumeration
  has_many :issues, :foreign_key => 'confidentiality_id'

  OptionName = :enumeration_document_confidentiality

  def option_name
    OptionName
  end

  def objects_count
    #documents.count
  end

  def transfer_relations(to)
    #documents.update_all(:category_id => to.id)
  end

  def self.default
    d = super
    d = first if d.nil?
    d
  end
end