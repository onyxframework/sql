struct Core::Query(ModelType)
  # :nodoc:
  alias HavingTuple = NamedTuple(clause: String, params: Array(DBValue)?)

  # :nodoc:
  property having_values = [] of HavingTuple

  # :nodoc:
  property or_having_values = [] of HavingTuple

  def reset
    having_values.clear
    or_having_values.clear
    super
  end

  # Add a `HAVING` *clause*, optionally interpolated with *params*. Multiple calls will join clauses with `AND`.
  #
  # ```
  # query.having("char_length(name) > ?", [10]).having("created_at > NOW()").to_s
  # # => HAVING (char_length(name) > ?) AND (created_at > NOW())
  # ```
  def having(clause : String, params : Array? = nil, or = false)
    tuple = HavingTuple.new(
      clause: clause,
      params: prepare_params(params),
    )

    if or
      @or_having_values << tuple
    else
      @having_values << tuple
    end

    @last_wherish_clause = :having

    self
  end

  # Add `HAVING` clauses just like `#having`.
  def and_having(clause : String, params : Array? = nil)
    having(clause, params)
  end

  # Add `HAVING` clauses just like `#or_having`.
  def or_having(clause : String, params : Array? = nil)
    having(clause, params, or: true)
  end

  # :nodoc:
  def self.having(clause : String, params : Array? = nil)
    new.having(clause, params)
  end

  # :nodoc:
  def self.and_having(clause : String, params : Array? = nil)
    new.and_having(clause, params)
  end

  # :nodoc:
  def self.or_having(clause : String, params : Array? = nil)
    new.and_having(clause, params, or: true)
  end

  # A convenient way to add `HAVING` clauses. Multiple clauses in a single call are joined with `AND`. Examples:
  #
  # ```
  # user = User.new(id: 42)
  # query = Query(Post).new
  #
  # # All clauses below will result in
  # # "HAVING (posts.author_id = ?)"
  # # with params [42]
  # query.having(author: user)
  # query.having(author_id: user.id)
  # query.having("posts.author_id = ?", [user.id])
  #
  # # Will result in
  # # "HAVING (posts.author_id IN (?, ?) AND posts.popular = ?)"
  # # with params [1, 2, true]
  # query.having(author_id: [1, 2], popular: true)
  #
  # # Will result in
  # # "HAVING (posts.author_id = ? AND posts.editor_id IS NULL)"
  # # with params [42]
  # query.having(author: user, editor: nil)
  #
  # # Will result in
  # # "HAVING (posts.author_id = ?) AND (posts.editor_id IS NOT NULL)"
  # # with params [42]
  # query.having(author: user).having(editor: !nil)
  #
  # # Will result in
  # # "HAVING (users.role = ?)"
  # # with params [1]
  # Query(User).new.having(role: User::Role::Admin)
  # ```
  def having(**having, or = false)
    group = [] of HavingTuple
    having.to_h.tap &.each do |key, value|
      reference_key = ModelType.reference_key(key) rescue nil
      column = ModelType.table_name + "." + (reference_key || key).to_s

      if value.nil?
        group << HavingTuple.new(
          clause: column + " IS NULL",
          params: nil,
        )
      elsif reference_key
        if value == true
          group << HavingTuple.new(
            clause: column + " IS NOT NULL",
            params: nil,
          )
        elsif value.is_a?(Core::Model)
          group << HavingTuple.new(
            clause: column + " = ?",
            params: prepare_params([value.primary_key_value]),
          )
        elsif value.is_a?(Array(Core::Model))
          group << HavingTuple.new(
            clause: column + " IN (" + value.size.times.map { "?" }.join(", ") + ")",
            params: prepare_params(value.map &.primary_key_value),
          )
        else
          raise ArgumentError.new("#{key} value must be either nil, true or Core::Model! Given: #{value.class}")
        end
      elsif ModelType.db_fields.keys.includes?(key)
        if value.is_a?(Array) && !value.is_a?(Array(Core::Model))
          group << HavingTuple.new(
            clause: column + " IN (" + value.size.times.map { "?" }.join(", ") + ")",
            params: prepare_params(value),
          )
        elsif value == true && ModelType.db_fields[key] != Bool
          group << HavingTuple.new(
            clause: column + " IS NOT NULL",
            params: nil,
          )
        elsif !value.is_a?(Core::Model)
          group << HavingTuple.new(
            clause: column + " = ?",
            params: prepare_params([value]),
          )
        else
          raise ArgumentError.new("Invalid value type used for #{key}! Given: #{value.class}")
        end
      else
        raise ArgumentError.new("A key must be either reference or a field! Given: #{key}")
      end
    end

    having(group.map(&.[:clause]).join(" AND "), group.map(&.[:params]).flatten, or: or)

    self
  end

  # Equals to `#having`.
  def and_having(**having)
    having(**having, or: false)
  end

  # :nodoc:
  def self.having(**having)
    new.having(**having)
  end

  # :nodoc:
  def self.and_having(**having)
    new.and_having(**having)
  end

  # A convenient way to add `OR HAVING` clauses. Multiple clauses in a single call are joined with `AND`. See `#having` for examples.
  def or_having(**having)
    having(**having, or: true)
  end

  # :nodoc:
  def self.or_having(**having)
    new.having(**having, or: true)
  end

  # :nodoc:
  macro having_clause
    having_clause_used = false

    if having_values.any?
      unless having_clause_used
        query += " HAVING "
        having_clause_used = true
      end

      query += having_values.map(&.[:clause]).join(" AND ") { |w| "(#{w})" }
      params.concat(having_values.map(&.[:params]).flatten.compact)
    end

    if or_having_values.any?
      if having_clause_used
        query += " OR "
      else
        query += " HAVING "
      end

      query += or_having_values.map(&.[:clause]).join(" OR ") { |w| "(#{w})" }
      params.concat(or_having_values.map(&.[:params]).flatten.compact)
    end
  end
end
