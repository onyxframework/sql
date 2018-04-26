struct Core::Query::Instance(Schema)
  private alias SetTuple = NamedTuple(clause: String, params: Array(::DB::Any)?)
  protected property set_clauses = [] of SetTuple

  # Append explicit value to `SET` clauses, setting Query type to `UPDATE`.
  #
  # ```
  # User.update.set("popularity = floor(random() * ?)", 100).to_s
  # # => UPDATE users SET popularity = floor(random() * ?) with params [100]
  # ```
  def set(clause, *params)
    update # Set Query type to UPDATE

    set_clauses << SetTuple.new(
      clause: clause,
      params: params.try &.to_a.map(&.as(::DB::Any))
    )

    self
  end

  # Append values to `SET` clauses, setting Query type to `UPDATE`.
  #
  # NOTE: It's not included in `Query` module to avoid confusion about possible `Schema#set` method. Use `Query#update` beforeahead.
  #
  # ```
  # User.update.set(active: true).to_s     # Equal
  # Query.new(User).set(active: true).to_s # Equal
  # # => UPDATE users SET active = true
  # ```
  def set(**values)
    values.to_h.each do |key, value|
      {% begin %}
        case key
        {% for field in Schema::INTERNAL__CORE_FIELDS %}
          when {{field[:name]}}
            set({{field[:key].id.stringify}} + " = ?", value)
        {% end %}
        else
          raise ArgumentError.new("Invalid field name #{key} for #{Schema}!")
        end
      {% end %}
    end

    self
  end

  # :nodoc:
  macro append_set_clauses
    if set_clauses.any?
      query += " SET " + set_clauses.map(&.[:clause]).join(", ")
      params.concat(set_clauses.map(&.[:params]).flatten.compact)
    end
  end
end
