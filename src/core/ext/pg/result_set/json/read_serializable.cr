{% if @type.has_constant?("PG") %}
  require "json"

  class PG::ResultSet < DB::ResultSet
    def read(t : JSON::Serializable.class)
      bytes = read_raw
      raise "PG::ResultSet#read_raw returned 'nil'. Bytes were expected." unless bytes
      t.from_json(String.new(bytes))
    end

    def read(t : (JSON::Serializable | Nil).class)
      read_raw.try { |bytes| t.from_json(String.new(bytes)) }
    end
  end
{% end %}
