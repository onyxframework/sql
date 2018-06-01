struct Core::Query::Instance(Schema)
  # :nodoc:
  protected property offset_clause : Int32 | Int64 | Nil = nil

  # Set `OFFSET` clause.
  #
  # ```
  # Core::Query::Instance(User).new.offset(5).to_s
  # # => SELECT users.* FROM users OFFSET 5
  # ```
  def offset(offset : Int32 | Int64 | Nil)
    @offset_clause = offset
    self
  end

  # :nodoc:
  macro append_offset_clause
    query += " OFFSET " + offset_clause.to_s if offset_clause
  end
end
