struct Core::Query(Schema)
  # :nodoc:
  property select_values : Array(Symbol | String) = [] of Symbol | String

  def reset
    select_values = [] of Symbol | String
    super
  end

  # Append values to `SELECT` clause, default to "*".
  #
  # ```
  # Query(User).new.select(:"DISTINCT name").to_s
  # # => SELECT DISTINCT name FROM users
  #
  # Query(User).new.select("DISTINCT name").select(:id, :role).to_s
  # # => SELECT DISTINCT name, id, role FROM users
  # ```
  def select(*values)
    @select_values.concat(values)
    self
  end

  # :nodoc:
  def self.select(*values)
    new.select(*values)
  end

  # :nodoc:
  macro select_clause
    query += "SELECT " + (select_values.any? ? select_values.join(", ") : "*")
  end
end
