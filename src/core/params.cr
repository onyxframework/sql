require "db"

module Core
  # Prepare *params* for database usage.
  #
  # ```
  # Core.prepare_params(42, "foo")
  # # => {42, "foo"}
  #
  # Core.prepare_params([42, 43], "foo")
  # # => {[42, 43], "foo"}
  # ```
  def self.prepare_params(*params)
    params.map do |p|
      if p.is_a?(Enumerable)
        p.map &.as(::DB::Any)
      else
        p.as(::DB::Any)
      end
    end
  end

  # It's a small hack to deal with recursion. See below.
  # :nodoc:
  def self.explicit_prepare_params(*params)
    params.map do |p|
      if p.is_a?(Enumerable)
        p.map(&.as(::DB::Any))
      else
        p.as(::DB::Any)
      end
    end
  end

  # Prepare *params* from `Enumerable`.
  #
  # ```
  # Core.prepare_params([42, "foo"])
  # # => {42, "foo"}
  # ```
  #
  # OPTIMIZE: Strictly type with (params : ArrayLiteral | SetLiteral)
  macro prepare_params(params)
    {% if params.is_a?(ArrayLiteral) || params.is_a?(SetLiteral) %}
      Core.prepare_params(
        {% for e in params %}
          {{e}},
        {% end %}
      )
    {% else %}
      # Dirty! But macros aren't strictly typed yet
      Core.explicit_prepare_params({{params}})
    {% end %}
  end
end
