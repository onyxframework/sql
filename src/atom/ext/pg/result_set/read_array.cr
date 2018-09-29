{% if @type.has_constant?("PG") %}
  class PG::ResultSet < DB::ResultSet
    # TODO: Directly overload `read` with certain Array types when https://github.com/crystal-lang/crystal/issues/6701 is fixed
    def read(t : Array(T).class) : Array(T) forall T
      {% verbatim do %}
        {% if T < Enum %}
          bytes = read.as(Bytes)
          String.new(bytes).delete("^a-z_\n").split("\n").map{ |s| T.parse(s) }
        {% elsif T <= UUID %}
          previous_def(Array(String)).map { |s| T.new(s) }
        {% elsif T < DB::Any %}
          previous_def(Array(T))
        {% else %}
          {% raise "Unsupported (yet) Array type #{T}" %}
        {% end %}
      {% end %}
    end

    # TODO: Directly overload `read` with certain Array types when https://github.com/crystal-lang/crystal/issues/6701 is fixed
    def read(t : (Array(T)?).class) : Array(T)? forall T
      {% verbatim do %}
        {% if T < Enum %}
          read.as(Bytes | Nil).try do |bytes|
            String.new(bytes).delete("^a-z_\n").split("\n").map{ |s| T.parse(s) }
          end
        {% elsif T <= URI %}
          previous_def(Array(String) | Nil).try &.map { |s| T.parse(s) }
        {% elsif T <= UUID %}
          previous_def(Array(String) | Nil).try &.map { |s| T.new(s) }
        {% elsif T < DB::Any %}
          previous_def(Array(T) | Nil)
        {% else %}
          {% raise "Unsupported (yet) Array type #{T}" %}
        {% end %}
      {% end %}
    end
  end
{% end %}
