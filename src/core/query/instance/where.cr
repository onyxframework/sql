require "./wherish"

struct Core::Query::Instance(Schema)
  # :nodoc:
  alias WhereTuple = NamedTuple(clause: String, params: Array(Param)?, or: Bool, not: Bool)
  alias InternalWhereTuple = NamedTuple(clause: String, params: Array(Param)?)

  # :nodoc:
  property where_clauses = [] of WhereTuple

  # Add a `WHERE` *clause*, optionally interpolated with *params*. Multiple calls will join clauses with `AND`.
  #
  # ```
  # query.where("char_length(name) > ?", [10]).and_not_where("created_at > NOW()").to_s
  # # => WHERE (char_length(name) > ?) AND NOT (created_at > NOW())
  # ```
  def where(clause : String, params : Array | Tuple | Nil = nil, or = false, not = false)
    @where_clauses << WhereTuple.new(clause: clause, params: params.try &.to_a.map(&.as(Param)), or: or, not: not)
    @last_wherish_clause = :where
    self
  end

  # A convenient way to add `WHERE` clauses. Multiple clauses in a single call are joined with `AND`. Examples:
  #
  # ```
  # user = User.new(id: 42)
  # query = Core::Query::Instance(Post).new
  #
  # # All clauses below will result in
  # # "WHERE (posts.author_id = ?)"
  # # with params [42]
  # query.where(author: user)
  # query.where(author_id: user.id)
  # query.where("posts.author_id = ?", user.id)
  #
  # # Will result in
  # # "WHERE (posts.author_id IN (?, ?) AND posts.popular = ?)"
  # # with params [1, 2, true]
  # query.where(author_id: [1, 2], popular: true)
  #
  # # Will result in
  # # "WHERE NOT ((posts.author_id = ? AND posts.editor_id IS NULL))"
  # # with params [42]
  # query.not_where(author: user, editor: nil)
  #
  # # Will result in
  # # "WHERE (posts.author_id = ?) OR NOT (posts.editor_id IS NOT NULL)"
  # # with params [42]
  # query.where(author: user).or_not_where(editor: !nil)
  #
  # # Will result in
  # # "WHERE (users.role = ?)"
  # # with params [1]
  # User.where(role: User::Role::Admin)
  # ```
  def where(or = false, not = false, **where)
    group = [] of InternalWhereTuple

    where.to_h.tap &.each do |key, value|
      {% begin %}
        case key
        {% for field in Schema::INTERNAL__CORE_FIELDS %}
          when {{field[:key]}}
            column = Schema.table + "." + {{field[:key].id.stringify}}

            if value.nil?
              next group << InternalWhereTuple.new(
                clause: column + " IS NULL",
                params: nil,
              )
            elsif value.is_a?(Enumerable)
              next group << InternalWhereTuple.new(
                clause: column + " IN (" + value.size.times.map { "?" }.join(", ") + ")",
                params: value.map{ |v| field_to_db({{field}}, v) },
              )
            {% unless field[:type] == "Bool" %}
              elsif value == true
                next group << InternalWhereTuple.new(
                  clause: column + " IS NOT NULL",
                  params: nil,
                )
            {% end %}
            else
              next group << InternalWhereTuple.new(
                clause: column + " = ?",
                params: Array(Param){field_to_db({{field}}, value)},
              )
            end
        {% end %}

        {% for reference in Schema::INTERNAL__CORE_REFERENCES %}
          when {{reference[:name]}}
            column = {{Schema::TABLE.id.stringify + "." + reference[:key].id.stringify}}

            if value.nil?
              next group << InternalWhereTuple.new(
                clause: column + " IS NULL",
                params: nil,
              )
            elsif value == true
              next group << InternalWhereTuple.new(
                clause: column + " IS NOT NULL",
                params: nil,
              )
            elsif value.is_a?({{reference[:type]}})
              next group << InternalWhereTuple.new(
                clause: column + " = ?",
                params: [value.primary_key.as(Param)],
              )
            elsif value.is_a?(Enumerable({{reference[:type]}}))
              next group << InternalWhereTuple.new(
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

    where(group.map(&.[:clause]).join(" AND "), group.map(&.[:params]).flatten, or: or, not: not)
  end

  # Add `WHERE NOT` clause.
  def where_not(clause, *params)
    where(clause, *params, not: true)
  end

  # Add `WHERE NOT` clause.
  def where_not(**where)
    where(**where, not: true)
  end

  {% for not in [true, false] %}
    {% for or in [true, false] %}
      # Add `{{or ? "OR " : "AND "}}{{"NOT " if not}}WHERE` clause.
      def {{(or ? "or" : "and").id}}_where{{"_not".id if not}}(clause, *params)
        where(clause, *params, or: {{or}}, not: {{not}})
      end

      # A convenient way to add `{{or ? "OR " : "AND "}}{{"NOT " if not}}WHERE` clauses. Multiple clauses in a single call are joined with `AND`. See `#where` for examples.
      def {{(or ? "or" : "and").id}}_where{{"_not".id if not}}(**where)
        where(**where, or: {{or}}, not: {{not}})
      end
    {% end %}
  {% end %}

  # :nodoc:
  macro append_where_clauses
    if where_clauses.any?
      query += " WHERE "
      first_clause = true

      query += where_clauses.join(" ") do |clause|
        s = ""
        s += (clause[:or] ? "OR " : "AND ") unless first_clause
        s += "NOT " if clause[:not]
        s += "(" + clause[:clause] + ")"

        first_clause = false

        s
      end

      params.concat(where_clauses.map(&.[:params]).flatten.compact)
    end
  end
end
