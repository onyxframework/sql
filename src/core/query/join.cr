struct Core::Query(Schema)
  alias JoinSelectType = Symbol | String | Char | Array(Symbol | String | Char)

  # :nodoc:
  alias JoinTuple = NamedTuple(table: Symbol | String, on: Tuple(Symbol | String, Symbol | String), "as": Symbol | String, "type": Symbol | String?, "select": JoinSelectType)

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
  def join(table : Symbol | String, on : Tuple(Symbol | String, Symbol | String), as _as : Symbol | String? = nil, type _type : Symbol | String? = nil, select _select : JoinSelectType = '*')
    join_values.push(JoinTuple.new(table: table, on: on, as: _as || table, type: _type, select: _select))
    self
  end

  # :nodoc:
  def self.join(table, on, as _as = nil, type _type = nil, select _select = '*')
    new.join(table, on, _as, _type, _select)
  end

  # `INNER JOIN` *table*. See `#join`.
  def inner_join(table, on, as _as = nil, select _select = '*')
    join(table, on, _as, :inner, _select)
  end

  # :nodoc:
  def self.inner_join(table, on, as _as = nil, select _select = '*')
    new.join(table, on, _as, :inner, _select)
  end

  {% for t in %i(left right full) %}
    # Verbose `{{t.id.stringify.upcase.id}} JOIN` by *table*. See `#join`.
    def {{t.id}}_join(table, on, as _as = nil, select _select = '*')
      join(reference, on, _as, {{t}}, _select)
    end

    # Verbose `{{t.id.stringify.upcase.id}} OUTER JOIN` by *table*. See `#join`.
    def {{t.id}}_outer_join(table, on, as _as = nil, select _select = '*')
      join(reference, on, _as, {{t}}_outer, _select)
    end

    # :nodoc:
    def self.{{t.id}}_join(table, on, as _as = nil, select _select = '*')
      new.join(reference, on, _as, {{t}}, _select)
    end

    # :nodoc:
    def self.{{t.id}}_outer_join(table, on, as _as = nil, select _select = '*')
      new.join(reference, on, _as, {{t}}_outer, _select)
    end
  {% end %}

  # `JOIN` *reference* - leverages schema's references' potential.
  #
  # - *reference* means **what** to join;
  # - *as* defines alias. Default to *reference*;
  # - *type* declares a joining type (e.g. :left_outer);
  # - *select* specifies which fields to select.
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
  # Query(Post).join(:author, select: :id).to_s
  # # => SELECT posts.*, '' AS _author, author.id FROM posts JOIN users AS author ON author.id = posts.author_id
  #
  # Query(User).join(:authored_posts, as: :written_posts).to_s
  # # => SELECT posts.*, '' as _post, written_posts.* FROM users JOIN posts AS written_posts ON users.id = written_posts.author_id
  #
  # Query(Post).right_outer_join(:editor).to_s         # Equal
  # Query(Post).join(:editor, type: :right_outer).to_s # Equal
  # # => SELECT posts.*, '' as _user, editor.* FROM posts RIGHT OUTER JOIN users AS editor ON editor.id = posts.editor_id
  # ```
  def join(reference : Symbol, as _as : Symbol? = nil, type _type : Symbol? = nil, select _select : JoinSelectType = '*')
    {% begin %}
      case reference
        {% for reference in Schema::INTERNAL__CORE_REFERENCES %}
          when {{reference[:name]}}
            on = {% if reference[:key] %}
              {{reference[:key]}}
            {% elsif reference[:foreign_key] %}
              {{Schema::PRIMARY_KEY[:name]}}
            {% else %}
              {% raise "Reference must have either foreign_key or key" %}
            {% end %}

            selects = map_select_to_field_keys({{reference[:type]}}, _select)
            append_mapping_marker({{reference[:name]}}, _as || {{reference[:name]}}, selects)

            join(
              table: {{reference[:type]}}.table,
              on: {
                {{reference[:foreign_key]}},
                on,
              },
              as: _as || {{reference[:name]}},
              type: _type,
              select: selects
            )
        {% end %}
        else
          raise "Unknown reference #{reference} for #{Schema}"
        end
    {% end %}
  end

  # :nodoc:
  def self.join(reference, as _as = nil, type _type = nil, select _select = '*')
    new.join(reference, _as, _type, _select)
  end

  @initial_select_wildcard_prefix : Bool = false

  # Append SELECT marker used for mapping. E.g. `append_mapping_marker("post")` would append "SELECT '' AS _post, posts.*"
  def append_mapping_marker(mappable_type_name, _as, _select = '*')
    if !@initial_select_wildcard_prefix
      self.select({{Schema::TABLE.id.stringify}} + ".*")
      @initial_select_wildcard_prefix = true
    end

    selects = if _select.is_a?(Enumerable)
                _select.map { |s| "#{_as}.#{s}" }.join(", ")
              else
                "#{_as}.#{_select}"
              end

    self.select("'' AS _#{mappable_type_name}, #{selects}")
  end

  macro map_select_to_field_keys(reference_type, selects)
    if {{selects}} == '*' || {{selects}} == :*
      '*'.as(JoinSelectType)
    else
      column_selects = Set(JoinSelectType).new
      {% for field in reference_type.resolve.constant("INTERNAL__CORE_FIELDS") %}
        if {{selects}}.is_a?(Enumerable) && ({{selects}}.includes?({{field[:name]}}) || ({{selects}}.includes?({{field[:name].id.stringify}})))
          column_selects.add({{field[:key].id.stringify}})
        elsif {{selects}}.to_s == {{field[:name].id.stringify}}
          column_selects.add({{field[:key].id.stringify}})
        end
      {% end %}
      column_selects.to_a
    end
  end

  # `INNER JOIN` *reference*. See `#join`.
  def inner_join(reference, as _as = nil, select _select = '*')
    join(reference, _as, :inner, _select)
  end

  # :nodoc:
  def self.inner_join(reference, as _as = nil, select _select = '*')
    new.join(reference, _as, :inner, _select)
  end

  {% for t in %i(left right full) %}
    # `{{t.id.stringify.upcase.id}} JOIN` *reference*. See `#join`.
    def {{t.id}}_join(reference, as _as = nil, select _select = '*')
      join(reference, _as, {{t}}, _select)
    end

    # `{{t.id.stringify.upcase.id}} OUTER JOIN` *reference*. See `#join`.
    def {{t.id}}_outer_join(reference, as _as = nil, select _select = '*')
      join(reference, _as, {{t}}_outer, _select)
    end

    # :nodoc:
    def self.{{t.id}}_join(reference, as _as = nil, select _select = '*')
      new.join(reference, _as, {{t}}, _select)
    end

    # :nodoc:
    def self.{{t.id}}_outer_join(reference, as _as = nil, select _select = '*')
      new.join(reference, _as, {{t}}_outer, _select)
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
        table:      Schema::TABLE,
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
