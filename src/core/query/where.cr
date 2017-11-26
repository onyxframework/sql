struct Core::Query(ModelType)
  # :nodoc:
  alias WhereTuple = NamedTuple(clause: String, params: Array(DBValue)?)

  # :nodoc:
  property where_values = [] of WhereTuple

  # :nodoc:
  property or_where_values = [] of WhereTuple

  def reset
    where_values.clear
    or_where_values.clear
    super
  end

  # Add a `WHERE` *clause*, optionally interpolated with *params*. Multiple calls will join clauses with `AND`.
  #
  # ```
  # query.where("char_length(name) > ?", [10]).where("created_at > NOW()").to_s
  # # => WHERE (char_length(name) > ?) AND (created_at > NOW())
  # ```
  def where(clause : String, params : Array? = nil, or = false)
    tuple = WhereTuple.new(
      clause: clause,
      params: prepare_params(params),
    )

    if or
      @or_where_values << tuple
    else
      @where_values << tuple
    end

    @last_wherish_clause = :where

    self
  end

  # ditto
  def self.where(clause : String, params : Array? = nil)
    new.where(clause, params)
  end

  # Add `WHERE` clauses just like `#where`.
  def and_where(clause : String, params : Array? = nil)
    where(clause, params)
  end

  # ditto
  def self.and_where(clause : String, params : Array? = nil)
    new.and_where(clause, params)
  end

  # Add `WHERE` clauses just like `#or_where`.
  def or_where(clause : String, params : Array? = nil)
    where(clause, params, or: true)
  end

  # ditto
  def self.or_where(clause : String, params : Array? = nil)
    new.and_where(clause, params, or: true)
  end

  # A convenient way to add `WHERE` clauses. Multiple clauses in a single call are joined with `AND`. Examples:
  #
  # ```
  # user = User.new(id: 42)
  # query = Query(Post).new
  #
  # # All clauses below will result in
  # # "WHERE (posts.author_id = ?)"
  # # with params [42]
  # query.where(author: user)
  # query.where(author_id: user.id)
  # query.where("posts.author_id = ?", [user.id])
  #
  # # Will result in
  # # "WHERE (posts.author_id IN (?, ?) AND posts.popular = ?)"
  # # with params [1, 2, true]
  # query.where(author_id: [1, 2], popular: true)
  #
  # # Will result in
  # # "WHERE (posts.author_id = ? AND posts.editor_id IS NULL)"
  # # with params [42]
  # query.where(author: user, editor: nil)
  #
  # # Will result in
  # # "WHERE (posts.author_id = ?) AND (posts.editor_id IS NOT NULL)"
  # # with params [42]
  # query.where(author: user).where(editor: !nil)
  #
  # # Will result in
  # # "WHERE (users.role = ?)"
  # # with params [1]
  # Query(User).new.where(role: User::Role::Admin)
  # ```
  def where(**where, or = false)
    group = [] of WhereTuple
    where.to_h.tap &.each do |key, value|
      reference_key = ModelType.reference_key(key) rescue nil
      column = ModelType.table_name + "." + (reference_key || key).to_s

      if value.nil?
        group << WhereTuple.new(
          clause: column + " IS NULL",
          params: nil,
        )
      elsif reference_key
        if value == true
          group << WhereTuple.new(
            clause: column + " IS NOT NULL",
            params: nil,
          )
        elsif value.is_a?(Core::Model)
          group << WhereTuple.new(
            clause: column + " = ?",
            params: prepare_params([value.primary_key_value]),
          )
        elsif value.is_a?(Array(Core::Model))
          group << WhereTuple.new(
            clause: column + " IN (" + value.size.times.map { "?" }.join(", ") + ")",
            params: prepare_params(value.map &.primary_key_value),
          )
        else
          raise ArgumentError.new("#{key} value must be either nil, true or Core::Model! Given: #{value.class}")
        end
      elsif ModelType.db_fields.keys.includes?(key)
        if value.is_a?(Array)
          if value.any?(&.is_a?(Core::Model))
            raise ArgumentError.new("Cannot use Core::Model as a value for #{key}!")
          end

          group << WhereTuple.new(
            clause: column + " IN (" + value.size.times.map { "?" }.join(", ") + ")",
            params: prepare_params(value),
          )
        elsif value == true && ModelType.db_fields[key] != Bool
          group << WhereTuple.new(
            clause: column + " IS NOT NULL",
            params: nil,
          )
        elsif !value.is_a?(Core::Model)
          group << WhereTuple.new(
            clause: column + " = ?",
            params: prepare_params([value]),
          )
        else
          raise ArgumentError.new("Cannot use Core::Model as a value for #{key}!")
        end
      else
        raise ArgumentError.new("The key must be either reference or a field! Given: #{key}")
      end
    end

    where(group.map(&.[:clause]).join(" AND "), group.map(&.[:params]).flatten, or: or)

    self
  end

  # ditto
  def self.where(**where)
    new.where(**where)
  end

  # Equals to `#where`.
  def and_where(**where)
    where(**where, or: false)
  end

  # ditto
  def self.and_where(**where)
    new.and_where(**where)
  end

  # A convenient way to add `OR WHERE` clauses. Multiple clauses in a single call are joined with `AND`. See `#where` for examples.
  def or_where(**where)
    where(**where, or: true)
  end

  # ditto
  def self.or_where(**where)
    new.where(**where, or: true)
  end

  # :nodoc:
  macro where_clause
    where_clause_used = false

    if where_values.any?
      unless where_clause_used
        query += " WHERE "
        where_clause_used = true
      end

      query += where_values.map(&.[:clause]).join(" AND ") { |w| "(#{w})" }
      params.concat(where_values.map(&.[:params]).flatten.compact)
    end

    if or_where_values.any?
      if where_clause_used
        query += " OR "
      else
        query += " WHERE "
      end

      query += or_where_values.map(&.[:clause]).join(" OR ") { |w| "(#{w})" }
      params.concat(or_where_values.map(&.[:params]).flatten.compact)
    end
  end
end
