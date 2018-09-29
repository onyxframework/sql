{% if @type.has_constant?("PG") %}
  require "uri"

  class PG::ResultSet < DB::ResultSet
    def read(t : URI.class)
      t.parse(read(String))
    end

    def read(t : (URI | Nil).class)
      read(String | Nil).try { |s| URI.parse(s) }
    end
  end
{% end %}
