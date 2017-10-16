struct Core::Query(ModelType)
  # :nodoc:
  alias JoinTuple = NamedTuple(reference: Symbol, on: Symbol?, "as": Symbol?, "type": Symbol?)

  # :nodoc:
  property join_values = [] of JoinTuple

  def reset
    join_values.clear
    super
  end

  # `JOIN` *reference*.
  #
  # - *reference* means **what** to join;
  # - *on* allows to determine **which** *reference*'s reference to use;
  # - *as* defines `AS`. Default to *reference*;
  # - *type* declares a joining type (e.g. `LEFT OUTER`).
  #
  # ```
  # class User
  #   primary_key :id
  #   reference :posts, Array(Post)
  # end
  #
  # class Post
  #   reference :author, User, key: :user_id
  #   reference :editor, User, key: :editor_id
  # end
  #
  # Query(Post).new.join(:author).to_s
  # # => SELECT * FROM posts JOIN users AS author ON author.id = posts.user_id
  #
  # Query(User).new.join(:posts, on: :author, as: :authored_posts).to_s
  # # => SELECT * FROM users JOIN posts AS authored_posts ON authored_posts.user_id = users.id
  #
  # Query(Post).new.right_outer_join(:author).to_s         # Equal
  # Query(Post).new.join(:author, type: :right_outer).to_s # Equal
  # # => SELECT * FROM posts RIGHT OUTER JOIN users AS author ON author.id = posts.user_id
  # ```
  def join(reference : Symbol, on : Symbol? = nil, as _as : Symbol? = nil, type _type : Symbol? = nil)
    join_values.push(JoinTuple.new(reference: reference, on: on, as: _as, type: _type))
    self
  end

  # :nodoc:
  def self.join(reference : Symbol, on : Symbol? = nil, as _as : Symbol? = nil, type _type : Symbol? = nil)
    new.join(reference, on, _as, _type)
  end

  # `INNER JOIN` *reference*. See `#join`.
  def inner_join(reference, on = nil, as _as = nil)
    join(reference, on, _as, :inner)
  end

  # :nodoc:
  def self.inner_join(reference, on = nil, as _as = nil)
    new.join(reference, on, _as, :inner)
  end

  {% for t in %i(left right full) %}
    # `{{t.id.stringify.upcase.id}} JOIN` *reference*. See `#join`.
    def {{t.id}}_join(reference, on = nil, as _as = nil)
      join(reference, on, _as, {{t}})
    end

    # `{{t.id.stringify.upcase.id}} OUTER JOIN` *reference*. See `#join`.
    def {{t.id}}_outer_join(reference, on = nil, as _as = nil)
      join(reference, on, _as, {{t}}_outer)
    end

    # :nodoc:
    def self.{{t.id}}_join(reference, on = nil, as _as = nil)
      new.join(reference, on, _as, {{t}})
    end

    # :nodoc:
    def self.{{t.id}}_outer_join(reference, on = nil, as _as = nil)
      new.join(reference, on, _as, {{t}}_outer)
    end
  {% end %}

  # :nodoc:
  macro join_clause
    join_clauses = join_values.map do |join|
      reference_class = ModelType.reference_class(join[:reference]).not_nil!

      reference_alias = join[:as] || join[:reference]

      {% begin %}
        join_type = case join[:type]
        when :inner
          "INNER JOIN"
        {% for t in %i(left right full) %}
          when {{t}}
            {{t.id.stringify.upcase + " JOIN"}}
          when {{t}}_outer
            {{t.id.stringify.upcase + " OUTER JOIN"}}
        {% end %}
        else
          "JOIN"
        end
      {% end %}

      if join[:on]
        join_type + " " + SQL_JOIN_AS_CLAUSE % {
          reference_table_name:  reference_class.table_name,
          alias:                 reference_alias,
          reference_foreign_key: reference_class.reference_key(join[:on]),
          table_name:            ModelType.table_name,
          reference_key:         reference_class.reference_foreign_key(join[:on]),
        }
      else
        join_type + " " + SQL_JOIN_AS_CLAUSE % {
          reference_table_name:  reference_class.table_name,
          alias:                 reference_alias,
          reference_foreign_key: ModelType.reference_foreign_key(join[:reference]),
          table_name:            ModelType.table_name,
          reference_key:         ModelType.reference_key(join[:reference]) || reference_class.primary_key,
        }
      end.as(String)
    end

    query += " " + join_clauses.join(" ") if join_clauses.any?
  end

  # :nodoc:
  SQL_JOIN_AS_CLAUSE = <<-SQL
  %{reference_table_name} AS %{alias} ON %{alias}.%{reference_foreign_key} = %{table_name}.%{reference_key}
  SQL
end
