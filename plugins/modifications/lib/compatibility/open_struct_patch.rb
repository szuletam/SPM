class OpenStruct2 < OpenStruct
  undef id if defined?(id)

  def to_h
    json
  end

  def [](key)
    json[key.to_s]
  end

  def json
    return @json if @json
    @json = JSON.parse(to_json)
    @json = @json['table'] if @json.has_key?('table')
    @json
  end
end
