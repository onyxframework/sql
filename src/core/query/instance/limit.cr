struct Core::Query::Instance(Schema)
  # :nodoc:
  protected property limit_clause : Int32 | Int64 | Nil = nil

  # Set `LIMIT` clause.
  #
  # ```
  # Query.new(User).limit(50).to_s
  # # => SELECT * FROM users LIMIT 50
  # ```
  def limit(limit : Int32 | Int64 | Nil)
    @limit_clause = limit
    self
  end

  # :nodoc:
  macro append_limit_clause
    query += " LIMIT " + limit_clause.to_s if limit_clause
  end
end
