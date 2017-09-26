struct Core::Query(ModelType)
  # :nodoc:
  property limit_value : Int32? = nil

  def reset
    limit_value = nil
    super
  end

  # Set `LIMIT` clause.
  #
  # ```
  # Query(User).new.limit(50).to_s
  # # => SELECT * FROM users LIMIT 50
  # ```
  def limit(limit : Int32 | Int64 | Nil)
    @limit_value = limit
    self
  end

  # :nodoc:
  def self.limit(limit : Int32 | Int64 | Nil)
    new.limit(limit)
  end

  # :nodoc:
  macro limit_clause
    query += " LIMIT " + limit_value.to_s if limit_value
  end
end
