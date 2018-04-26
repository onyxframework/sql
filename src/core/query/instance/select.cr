struct Core::Query::Instance(Schema)
  # :nodoc:
  protected property select_clauses = [] of String

  # Append values to `SELECT` clauses either by field name (Symbol) or explicitly by String, default to "*".
  #
  # ```
  # class User
  #   include Core::Schema
  #   include Core::Query

  #   schema :users do
  #     primary_key :id
  #     field :foo, String
  #     field :bar, String, key: :baz
  #   end
  # end
  #
  # Query.new(User).select("name").to_s
  # # => SELECT name FROM users
  #
  # User.select("DISTINCT name").select(:foo, :bar).to_s
  # # => SELECT DISTINCT name, foom baz FROM users
  #
  # User.select(:id).select("*")
  # # => SELECT id, * FROM users
  # ```
  def select(*values)
    values.to_a.each do |value|
      if value.is_a?(String)
        select_clauses << value
      elsif value.is_a?(Symbol)
        {% begin %}
          case value
          {% for field in Schema::INTERNAL__CORE_FIELDS %}
            when {{field[:name]}}
              select_clauses << {{field[:key].id.stringify}}
          {% end %}
          else
            raise ArgumentError.new("Invalid field name #{value} for #{Schema}!")
          end
        {% end %}
      else
        raise ArgumentError.new("A value to select must be either String or Symbol! Given: #{value.class}")
      end
    end

    self
  end

  # :nodoc:
  macro append_select_clauses
    query += "SELECT " + (select_clauses.any? ? select_clauses.join(", ") : "*")
  end
end
