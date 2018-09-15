{% if @type.has_constant?("PG") %}
  require "uuid"

  class PG::ResultSet < DB::ResultSet
    def read(t : UUID.class)
      t.new(read(String))
    end

    def read(t : (UUID | Nil).class)
      read(String | Nil).try { |s| UUID.new(s) }
    end
  end
{% end %}
