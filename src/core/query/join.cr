struct Core::Query(ModelType)
  # :nodoc:
  alias JoinTuple = NamedTuple(table: Symbol | String, on: Tuple(Symbol | String, Symbol | String), "as": Symbol | String, "type": Symbol | String?)

  # :nodoc:
  property join_values = [] of JoinTuple

  def reset
    join_values.clear
    super
  end

  # Verbose `JOIN` by *table*.
  #
  # ```
  # Query(User).join(:posts, on: {:author_id, :id}, as: :written_posts)
  # # => SELECT * FROM users JOIN posts AS written_posts ON written_posts.author_id = users.id
  # ```
  def join(table : Symbol | String, on : Tuple(Symbol | String, Symbol | String), as _as : Symbol | String? = nil, type _type : Symbol | String? = nil)
    join_values.push(JoinTuple.new(table: table, on: on, as: _as || table, type: _type))
    self
  end

  # :nodoc:
  def self.join(table, on, as _as = nil, type _type = nil)
    new.join(table, on, _as, _type)
  end

  # `INNER JOIN` *table*. See `#join`.
  def inner_join(table, on, as _as = nil)
    join(table, on, _as, :inner)
  end

  # :nodoc:
  def self.inner_join(table, on, as _as = nil)
    new.join(table, on, _as, :inner)
  end

  {% for t in %i(left right full) %}
    # Verbose `{{t.id.stringify.upcase.id}} JOIN` by *table*. See `#join`.
    def {{t.id}}_join(table, on, as _as = nil)
      join(reference, on, _as, {{t}})
    end

    # Verbose `{{t.id.stringify.upcase.id}} OUTER JOIN` by *table*. See `#join`.
    def {{t.id}}_outer_join(table, on, as _as = nil)
      join(reference, on, _as, {{t}}_outer)
    end

    # :nodoc:
    def self.{{t.id}}_join(table, on, as _as = nil)
      new.join(reference, on, _as, {{t}})
    end

    # :nodoc:
    def self.{{t.id}}_outer_join(table, on, as _as = nil)
      new.join(reference, on, _as, {{t}}_outer)
    end
  {% end %}

  # `JOIN` *reference* - leverages schema's references' potential.
  #
  # - *reference* means **what** to join;
  # - *as* defines alias. Default to *reference*;
  # - *type* declares a joining type (e.g. :left_outer).
  #
  # ```
  # class User
  #   primary_key :id
  #   reference :authored_posts, Array(Post), foreign_key: :author_id
  #   reference :edited_posts, Array(Post), foreign_key: :editor_id
  # end
  #
  # class Post
  #   reference :author, User, key: :author_id
  #   reference :editor, User, key: :editor_id
  # end
  #
  # Query(Post).join(:author).to_s
  # # => SELECT * FROM posts JOIN users AS author ON author.id = posts.author_id
  #
  # Query(User).join(:authored_posts, as: :written_posts).to_s
  # # => SELECT * FROM users JOIN posts AS written_posts ON users.id = written_posts.author_id
  #
  # Query(Post).right_outer_join(:editor).to_s         # Equal
  # Query(Post).join(:editor, type: :right_outer).to_s # Equal
  # # => SELECT * FROM posts RIGHT OUTER JOIN users AS editor ON editor.id = posts.editor_id
  # ```
  def join(reference : Symbol, as _as : Symbol? = nil, type _type : Symbol? = nil)
    {% begin %}
      case reference
        {% for reference in ModelType::INTERNAL__CORE_REFERENCES %}
          when {{reference[:name]}}
            {% if reference[:key] %}
              append_mapping_marker({{reference[:name]}}, _as || {{reference[:name]}})
              join(
                table: {{reference[:type]}}.table,
                on: {
                  {{reference[:foreign_key]}},
                  {{reference[:key]}},
                },
                as: _as || {{reference[:name]}},
                type: _type,
                )
              {% elsif reference[:foreign_key] %}
                append_mapping_marker({{reference[:name]}}, _as || {{reference[:name]}})
                join(
                table: {{reference[:type]}}.table,
                on: {
                  {{reference[:foreign_key]}},
                  {{ModelType::PRIMARY_KEY[:name]}},
                },
                as: _as || {{reference[:name]}},
                type: _type,
              )
            {% else %}
              {% raise "Reference must have either foreign_key or key" %}
            {% end %}
        {% end %}
        else
          raise "Unknown reference #{reference} for #{ModelType}"
        end
    {% end %}
  end

  # :nodoc:
  def self.join(reference, as _as = nil, type _type = nil)
    new.join(reference, _as, _type)
  end

  @initial_select_wildcard_prefix : Bool = false

  # Append SELECT marker used for mapping. E.g. `append_mapping_marker("post")` would append "SELECT '' AS _post, posts.*"
  def append_mapping_marker(mappable_type_name, as _as)
    if !@initial_select_wildcard_prefix
      self.select({{ModelType::TABLE.id.stringify}} + ".*")
      @initial_select_wildcard_prefix = true
    end

    self.select("'' AS _#{mappable_type_name}, #{_as}.*")
  end

  # `INNER JOIN` *reference*. See `#join`.
  def inner_join(reference, as _as = nil)
    join(reference, _as, :inner)
  end

  # :nodoc:
  def self.inner_join(reference, as _as = nil)
    new.join(reference, _as, :inner)
  end

  {% for t in %i(left right full) %}
    # `{{t.id.stringify.upcase.id}} JOIN` *reference*. See `#join`.
    def {{t.id}}_join(reference, as _as = nil)
      join(reference, _as, {{t}})
    end

    # `{{t.id.stringify.upcase.id}} OUTER JOIN` *reference*. See `#join`.
    def {{t.id}}_outer_join(reference, as _as = nil)
      join(reference, _as, {{t}}_outer)
    end

    # :nodoc:
    def self.{{t.id}}_join(reference, as _as = nil)
      new.join(reference, _as, {{t}})
    end

    # :nodoc:
    def self.{{t.id}}_outer_join(reference, as _as = nil)
      new.join(reference, _as, {{t}}_outer)
    end
  {% end %}

  # :nodoc:
  macro join_clause
    join_clauses = join_values.map do |join|
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

      (join_type + " " + SQL_JOIN_AS_CLAUSE % {
        join_table: join[:table],
        alias:      join[:as],
        join_key:   join[:on][0],
        table:      ModelType::TABLE,
        key:        join[:on][1],
      }).as(String)
    end

    query += " " + join_clauses.join(" ") if join_clauses.any?
  end

  # :nodoc:
  SQL_JOIN_AS_CLAUSE = <<-SQL
  %{join_table} AS "%{alias}" ON "%{alias}".%{join_key} = %{table}.%{key}
  SQL
end
