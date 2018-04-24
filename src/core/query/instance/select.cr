struct Core::Query::Instance(Schema)
  # :nodoc:
  protected property select_clauses = [] of String

  # Append values to `SELECT` clause, default to "*".
  #
  # ```
  # Query.new(User).select("DISTINCT name").to_s
  # # => SELECT DISTINCT name FROM users
  #
  # Query.new(User).select("DISTINCT name").select(:id, :role).to_s
  # # => SELECT DISTINCT name, id, role FROM users
  # ```
  def select(*values)
    @select_clauses.concat(values.map(&.to_s))
    self
  end

  # :nodoc:
  macro append_select_clauses
    query += "SELECT " + (select_clauses.any? ? select_clauses.join(", ") : "*")
  end
end
