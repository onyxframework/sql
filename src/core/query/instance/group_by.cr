struct Core::Query::Instance(Schema)
  # :nodoc:
  protected property group_by_clauses = [] of String

  # Append values to `GROUP_BY` clause.
  #
  # ```
  # Core::Query::Instance(User).new.group_by("users.id").to_s
  # # => SELECT users.* FROM users GROUP_BY users.id
  # ```
  def group_by(*group_by)
    @group_by_clauses.concat(group_by.to_a.flatten.map(&.to_s))
    self
  end

  # :nodoc:
  macro append_group_by_clauses
    query += " GROUP BY " + group_by_clauses.join(", ") if group_by_clauses.any?
  end
end
