{% if @type.has_constant?("PG") %}
  require "json"

  class PG::ResultSet < DB::ResultSet
    # TODO: `def read(t : (Hash | Nil).class)` leads to "can't use Hash(K, V) in unions yet, use a more specific type", therefore this call is nilable
    def read(t : Hash.class)
      read(String | Nil).try { |s| t.new(JSON::PullParser.new(s)) }
    end
  end
{% end %}
