struct Core::Query::Instance(Schema)
  # :nodoc:
  alias JoinSelectType = String | Symbol | Array(String | Symbol) | Nil

  # :nodoc:
  alias JoinTuple = NamedTuple(
    table: String,
    on: Tuple(String, String),
    "as": String,
    "type": Symbol?,
    "select": String | Array(String),
  )

  # :nodoc:
  protected property join_clauses = [] of JoinTuple

  # Verbose `JOIN` by *table*. Selects all joined columns by default.
  #
  # ```
  # User.join(:posts, on: {:author_id, :id}, as: :written_posts).to_s
  # # => SELECT * FROM users JOIN posts AS written_posts ON written_posts.author_id = users.id
  # ```
  def join(
    table : Symbol | String,
    on : Tuple(Symbol | String, Symbol | String),
    as _as : Symbol | String? = nil,
    type _type : Symbol? = nil,
    select _select : JoinSelectType = "*"
  )
    @join_clauses.push(JoinTuple.new(
      table: table.to_s,
      on: on.map(&.to_s),
      as: _as.try(&.to_s) || table.to_s,
      type: _type,
      select: _select.is_a?(Enumerable) ? _select.map(&.to_s) : _select.to_s,
    ))

    self
  end

  # `JOIN` *reference* - leverages schema's references' potential.
  #
  # - *reference* means **what** to join;
  # - *as* defines alias. Default to *reference*;
  # - *type* declares a joining type (e.g. :left_outer);
  # - *select* specifies which fields to select (`nil` for none, `*` by default).
  #
  # ```
  # class User
  #   include Core::Schema
  #   include Core::Query
  #
  #   schema :users do
  #     primary_key :id
  #     reference :authored_posts, Array(Post), foreign_key: :author_id
  #     reference :edited_posts, Array(Post), foreign_key: :editor_id
  #   end
  # end
  #
  # class Post
  #   include Core::Schema
  #   include Core::Query
  #
  #   schema :users do
  #     primary_key :id
  #     reference :author, User, key: :author_id
  #     reference :editor, User, key: :editor_id
  #   end
  # end
  #
  # Post.join(:author, select: :id).to_s
  # # => SELECT posts.*, '' AS _author, author.id FROM posts JOIN users AS author ON author.id = posts.author_id
  #
  # Post.join(:author, select: nil).where("author.id = ?", [1]).to_s
  # # => SELECT posts.* FROM posts JOIN users AS author ON author.id = posts.author_id WHERE author.id = ?
  #
  # User.join(:authored_posts, as: :written_posts).to_s
  # # => SELECT posts.*, '' as _post, written_posts.* FROM users JOIN posts AS written_posts ON users.id = written_posts.author_id
  #
  # Post.right_outer_join(:editor).to_s                    # Equal
  # Query.new(Post).join(:editor, type: :right_outer).to_s # Equal
  # # => SELECT posts.*, '' as _user, editor.* FROM posts RIGHT OUTER JOIN users AS editor ON editor.id = posts.editor_id
  # ```
  def join(reference : Symbol, as _as : Symbol? = nil, type _type : Symbol? = nil, select _select : JoinSelectType = "*")
    {% begin %}
      case reference
        {% for reference in Schema::INTERNAL__CORE_REFERENCES %}
          when {{reference[:name]}}
            on = {% if reference[:key] %}
              {{reference[:key]}}
            {% elsif reference[:foreign_key] %}
              Schema.primary_key[:name]
            {% else %}
              {% raise "Reference must have either foreign_key or key" %}
            {% end %}

            if _select
              _mapped_select = map_select_to_field_keys({{reference[:type]}}, _select)
              append_mapping_marker({{reference[:name]}}, _as || {{reference[:name]}}, _mapped_select)
            end

            join(
              table: {{reference[:type]}}.table,
              on: {
                {{reference[:foreign_key]}},
                "#{Schema.table}.#{on}",
              },
              as: _as || {{reference[:name]}},
              type: _type
            )
        {% end %}
        else
          raise "Unknown reference #{reference} for #{Schema}"
        end
    {% end %}
  end

  # Append SELECT marker used for mapping. E.g. `append_mapping_marker("post")` would append "SELECT '' AS _post, posts.*"
  def append_mapping_marker(mappable_type_name, _as, _select = "*")
    if select_clauses.empty?
      self.select({{Schema::TABLE.id.stringify}} + ".*")
    end

    _select = if _select.is_a?(Enumerable)
                _select.map { |s| "#{_as}.#{s}" }.join(", ")
              else
                "#{_as}.#{_select}"
              end

    self.select("'' AS _#{mappable_type_name}, #{_select}")
  end

  macro map_select_to_field_keys(reference_type, selects)
    if {{selects}} == "*" || {{selects}} == :*
      "*"
    else
      column_selects = Set(String).new
      {% for field in reference_type.resolve.constant("INTERNAL__CORE_FIELDS") %}
        if ({{selects}}.is_a?(Enumerable) && ({{selects}}.includes?({{field[:name]}}) || ({{selects}}.includes?({{field[:name].id.stringify}})))) || ({{selects}}.to_s == {{field[:name].id.stringify}})
          column_selects.add({{field[:key].id.stringify}})
        end
      {% end %}
      column_selects.to_a
    end
  end

  # `INNER JOIN` *table*. See `#join`.
  def inner_join(table, on, as _as = nil, select _select = "*")
    join(table, on, _as, :inner, _select)
  end

  # `INNER JOIN` *reference*. See `#join`.
  def inner_join(reference, as _as = nil, select _select = "*")
    join(reference, _as, :inner, _select)
  end

  {% for t in %i(left right full) %}
    # Verbose `{{t.id.stringify.upcase.id}} JOIN` by *table*. See `#join`.
    def {{t.id}}_join(table, on, as _as = nil, select _select = "*")
      join(reference, on, _as, {{t}}, _select)
    end

    # Verbose `{{t.id.stringify.upcase.id}} OUTER JOIN` by *table*. See `#join`.
    def {{t.id}}_outer_join(table, on, as _as = nil, select _select = "*")
      join(reference, on, _as, {{t}}_outer, _select)
    end

    # `{{t.id.stringify.upcase.id}} JOIN` *reference*. See `#join`.
    def {{t.id}}_join(reference, as _as = nil, select _select = "*")
      join(reference, _as, {{t}}, _select)
    end

    # `{{t.id.stringify.upcase.id}} OUTER JOIN` *reference*. See `#join`.
    def {{t.id}}_outer_join(reference, as _as = nil, select _select = "*")
      join(reference, _as, {{t}}_outer, _select)
    end
  {% end %}

  # :nodoc:
  macro append_join_clauses
    _join_clauses = join_clauses.map do |join|
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
        table:      Schema.table,
        key:        join[:on][1],
      }).as(String)
    end

    query += " " + _join_clauses.join(" ") if _join_clauses.any?
  end

  # :nodoc:
  SQL_JOIN_AS_CLAUSE = <<-SQL
  %{join_table} AS "%{alias}" ON "%{alias}".%{join_key} = %{key}
  SQL
end
