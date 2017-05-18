module RatiosHelper
  def evm_csv(evm)
    decimal_separator = l(:general_csv_decimal_separator)
    export = Redmine::Export::CSV.generate do |csv|
      fields = ["", "cpi", "spi"]
      csv << fields.collect {|c| Redmine::CodesetUtil.from_utf8(
                                      c,
                                      l(:general_csv_encoding))}
      fields = []
      fields << Redmine::CodesetUtil.from_utf8(evm[:name], l(:general_csv_encoding))
      fields << evm[:indicators][1].to_s.gsub('.', decimal_separator)
      fields << evm[:indicators][2].to_s.gsub('.', decimal_separator)
      csv << fields.collect {|c| Redmine::CodesetUtil.from_utf8(
                                     c,
                                     l(:general_csv_encoding))}
      evm[:indicators][0].each do |ent|
        csv << ent.collect {|c| Redmine::CodesetUtil.from_utf8(
                                       c.to_s.gsub('.', decimal_separator),
                                       l(:general_csv_encoding))}
        end
    end
    export
  end
end
