struct Core::Query(ModelType)
  # :nodoc:
  alias OrderByTuple = NamedTuple(column: Symbol, order: Symbol?)

  # :nodoc:
  property order_by_values = [] of OrderByTuple

  def reset
    order_by_values.clear
    super
  end

  # Add `ORDER BY` clause. Only `Symbol`s are accepted.
  #
  # ```
  # Query(User).new.order_by(:name, :DESC).to_s
  # # => SELECT * FROM users ORDER BY name DESC
  # ```
  def order_by(column : Symbol, order : Symbol? = nil)
    @order_by_values.push(OrderByTuple.new(
      column: column,
      order: order,
    ))
    self
  end

  # :nodoc:
  def self.order_by(column : Symbol, order : Symbol? = nil)
    new.order_by(column, order)
  end

  # :nodoc:
  macro order_by_clause
    order_by_clauses = order_by_values.map do |order_by|
      t = order_by[:column].to_s
      t += " " + order_by[:order].to_s if order_by[:order]
      t
    end
    query += " ORDER BY " + order_by_clauses.join(", ") if order_by_clauses.any?
  end
end
