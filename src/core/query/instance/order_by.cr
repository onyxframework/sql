struct Core::Query::Instance(Schema)
  # :nodoc:
  alias OrderByTuple = NamedTuple(column: String, order: String?)

  # :nodoc:
  protected property order_by_clauses = [] of OrderByTuple

  # Add `ORDER BY` clause. Only `Symbol`s are accepted.
  #
  # ```
  # Query.new(User).order_by(:name, :DESC).to_s
  # # => SELECT * FROM users ORDER BY name DESC
  # ```
  def order_by(column : Symbol | String, order : Symbol | String | Nil = nil)
    if column.is_a?(Symbol)
      {% begin %}
        case column
        {% for field in Schema::INTERNAL__CORE_FIELDS %}
          when {{field[:name]}}
            column = {{field[:key].id.stringify}}
        {% end %}
        else
          raise ArgumentError.new("Invalid field name #{column} for #{Schema}!")
        end
      {% end %}
    end

    @order_by_clauses.push(OrderByTuple.new(
      column: column,
      order: order.try &.to_s.upcase,
    ))

    self
  end

  # :nodoc:
  macro append_order_by_clauses
    _order_by_clauses = order_by_clauses.map do |order_by_clauses|
      t = order_by_clauses[:column]
      t += " " + order_by_clauses[:order].not_nil! if order_by_clauses[:order]
      t
    end

    query += " ORDER BY " + _order_by_clauses.join(", ") if _order_by_clauses.any?
  end
end
