struct Core::Query(ModelType)
  # :nodoc:
  property group_by_values = Array(Symbol).new

  def reset
    group_by_values.clear
    super
  end

  # Append values to `GROUP_BY` clause.
  #
  # NOTE: Only `Symbol`s are accepted.
  #
  # ```
  # Query(User).new.group_by(:"users.id").to_s
  # # => SELECT * FROM users GROUP_BY users.id
  def group_by(*group_by)
    @group_by_values.concat(group_by.to_a.flatten)
    self
  end

  # :nodoc:
  def self.group_by(*group_by)
    new.group_by(*group_by)
  end

  # :nodoc:
  macro group_by_clause
    query += " GROUP BY " + group_by_values.map(&.to_s).join(", ") if group_by_values.any?
  end
end
