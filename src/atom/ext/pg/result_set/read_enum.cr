{% if @type.has_constant?("PG") %}
  require "uri"

  class PG::ResultSet < DB::ResultSet
    # TODO: `def read(t : (Enum | Nil).class)` leads to "can't use Enum in unions yet, use a more specific type", therefore this call is nilable
    def read(t : Enum.class)
      read(Bytes | Nil).try { |bytes| t.parse(String.new(bytes)) }
    end
  end
{% end %}
