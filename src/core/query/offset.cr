struct Core::Query(ModelType)
  # :nodoc:
  property offset_value : Int32? = nil

  def reset
    offset_value = nil
    super
  end

  # Set `OFFSET` clause.
  #
  # ```
  # Query(User).new.offset(5).to_s
  # # => SELECT * FROM users OFFSET 5
  # ```
  def offset(offset : Int32 | Int64)
    @offset_value = offset
    self
  end

  # :nodoc:
  def self.offset(offset : Int32 | Int64)
    new.offset(offset)
  end

  # :nodoc:
  macro offset_clause
    query += " OFFSET " + offset_value.to_s if offset_value
  end
end
