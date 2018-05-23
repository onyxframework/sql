require "./wherish"

struct Core::Query::Instance(Schema)
  # :nodoc:
  alias HavingTuple = NamedTuple(clause: String, params: Array(Param)?, or: Bool, not: Bool)
  alias InternalHavingTuple = NamedTuple(clause: String, params: Array(Param)?)

  # :nodoc:
  property having_clauses = [] of HavingTuple

  # Add a `HAVING` *clause*, optionally interpolated with *params*. Multiple calls will join clauses with `AND`.
  #
  # ```
  # query.having("char_length(name) > ?", [10]).and_not_having("created_at > NOW()").to_s
  # # => HAVING (char_length(name) > ?) AND NOT (created_at > NOW())
  # ```
  def having(clause : String, params : Array | Tuple | Nil = nil, or = false, not = false)
    @having_clauses << HavingTuple.new(clause: clause, params: params.try &.to_a.map(&.as(Param)), or: or, not: not)
    @last_wherish_clause = :having
    self
  end

  # A convenient way to add `HAVING` clauses. Multiple clauses in a single call are joined with `AND`. Examples:
  #
  # ```
  # user = User.new(id: 42)
  # query = Query.new(Post)
  #
  # # All clauses below will result in
  # # "HAVING (posts.author_id = ?)"
  # # with params [42]
  # query.having(author: user)
  # query.having(author_id: user.id)
  # query.having("posts.author_id = ?", user.id)
  #
  # # Will result in
  # # "HAVING (posts.author_id IN (?, ?) AND posts.popular = ?)"
  # # with params [1, 2, true]
  # query.having(author_id: [1, 2], popular: true)
  #
  # # Will result in
  # # "HAVING NOT ((posts.author_id = ? AND posts.editor_id IS NULL))"
  # # with params [42]
  # query.not_having(author: user, editor: nil)
  #
  # # Will result in
  # # "HAVING (posts.author_id = ?) OR NOT (posts.editor_id IS NOT NULL)"
  # # with params [42]
  # query.having(author: user).or_not_having(editor: !nil)
  #
  # # Will result in
  # # "HAVING (users.role = ?)"
  # # with params [1]
  # User.having(role: User::Role::Admin)
  # ```
  def having(or = false, not = false, **having)
    group = [] of InternalHavingTuple

    having.to_h.tap &.each do |key, value|
      {% begin %}
        case key
        {% for field in Schema::INTERNAL__CORE_FIELDS %}
          when {{field[:key]}}
            column = Schema.table + "." + {{field[:key].id.stringify}}

            if value.nil?
              next group << InternalHavingTuple.new(
                clause: column + " IS NULL",
                params: nil,
              )
            elsif value.is_a?(Enumerable)
              next group << InternalHavingTuple.new(
                clause: column + " IN (" + value.size.times.map { "?" }.join(", ") + ")",
                params: value.map{ |v| field_to_db({{field}}, v) },
              )
            {% unless field[:type] == "Bool" %}
              elsif value == true
                next group << InternalHavingTuple.new(
                  clause: column + " IS NOT NULL",
                  params: nil,
                )
            {% end %}
            else
              next group << InternalHavingTuple.new(
                clause: column + " = ?",
                params: Array(Param){field_to_db({{field}}, value)},
              )
            end
        {% end %}

        {% for reference in Schema::INTERNAL__CORE_REFERENCES %}
          when {{reference[:name]}}
            column = {{Schema::TABLE.id.stringify + "." + reference[:key].id.stringify}}

            if value.nil?
              next group << InternalHavingTuple.new(
                clause: column + " IS NULL",
                params: nil,
              )
            elsif value == true
              next group << InternalHavingTuple.new(
                clause: column + " IS NOT NULL",
                params: nil,
              )
            elsif value.is_a?({{reference[:type]}})
              next group << InternalHavingTuple.new(
                clause: column + " = ?",
                params: [value.primary_key.as(Param)],
              )
            elsif value.is_a?(Enumerable({{reference[:type]}}))
              next group << InternalHavingTuple.new(
                clause: column + " IN (" + value.size.times.map { "?" }.join(", ") + ")",
                params: value.map &.primary_key.as(Param),
              )
            else
              raise ArgumentError.new("#{key} value must be either nil, true, {{reference[:class].id}} or Enumerable({{reference[:class].id}})! Given: #{value.class}")
            end
        {% end %}
        else
          raise ArgumentError.new("The key must be either reference or a field! Given: #{key}")
        end
      {% end %}
    end

    having(group.map(&.[:clause]).join(" AND "), group.map(&.[:params]).flatten, or: or, not: not)
  end

  # Add `HAVING NOT` clause.
  def not_having(clause, *params)
    having(clause, *params, not: true)
  end

  # Add `HAVING NOT` clause.
  def not_having(**having)
    having(**having, not: true)
  end

  {% for not in [true, false] %}
    {% for or in [true, false] %}
      # Add `{{or ? "OR " : "AND "}}{{"NOT " if not}}HAVING` clause.
      def {{(or ? "or" : "and").id}}{{"_not".id if not}}_having(clause, *params)
        having(clause, *params, or: {{or}}, not: {{not}})
      end

      # A convenient way to add `{{or ? "OR " : "AND "}}{{"NOT " if not}}HAVING` clauses. Multiple clauses in a single call are joined with `AND`. See `#having` for examples.
      def {{(or ? "or" : "and").id}}{{"_not".id if not}}_having(**having)
        having(**having, or: {{or}}, not: {{not}})
      end
    {% end %}
  {% end %}

  # :nodoc:
  macro append_having_clauses
    if having_clauses.any?
      query += " HAVING "
      first_clause = true

      query += having_clauses.join(" ") do |clause|
        s = ""
        s += (clause[:or] ? "OR " : "AND ") unless first_clause
        s += "NOT " if clause[:not]
        s += "(" + clause[:clause] + ")"

        first_clause = false

        s
      end

      params.concat(having_clauses.map(&.[:params]).flatten.compact)
    end
  end
end
