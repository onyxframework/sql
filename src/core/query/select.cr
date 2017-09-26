struct Core::Query(ModelType)
  # :nodoc:
  property select_values : Array(Symbol) = [:*]

  def reset
    select_values = [:*]
    super
  end

  # Set values for `SELECT` clause, default to [:*].
  #
  # NOTE: Only `Symbol`s are accepted.
  #
  # ```
  # Query(User).new.select(:"DISTINCT name").to_s
  # # => SELECT DISTINCT name FROM users
  def select(*selects)
    @select_values.replace(selects.to_a.flatten)
    self
  end

  # :nodoc:
  def self.select(*selects)
    new.select(*selects)
  end

  # :nodoc:
  macro select_clause
    query += "SELECT " + select_values.join(", ")
  end
end
