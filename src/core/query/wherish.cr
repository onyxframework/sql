struct Core::Query(ModelType)
  # `WHERE` and `HAVING` clauses follow the same rules, so I decided to reduce duplication with this macro.
  {% for wherish in %w(where having) %}
    # :nodoc:
    alias {{wherish.capitalize.id}}Tuple = NamedTuple(clause: String, params: Array(DBValue)?)

    # :nodoc:
    property {{wherish.id}}_values = [] of {{wherish.capitalize.id}}Tuple

    # :nodoc:
    property or_{{wherish.id}}_values = [] of {{wherish.capitalize.id}}Tuple

    def reset
      {{wherish.id}}_values.clear
      or_{{wherish.id}}_values.clear
      super
    end

    # Add a `{{wherish.upcase.id}}` *clause*, optionally interpolated with *params*. Multiple calls will join clauses with `AND`.
    #
    # ```
    # query.{{wherish.id}}("char_length(name) > ?", [10]).{{wherish.id}}("created_at > NOW()").to_s
    # # => {{wherish.upcase.id}} (char_length(name) > ?) AND (created_at > NOW())
    # ```
    def {{wherish.id}}(clause : String, params : Array? = nil, or = false)
      tuple = {{wherish.capitalize.id}}Tuple.new(
        clause: clause,
        params: prepare_params(params),
      )

      if or
        @or_{{wherish.id}}_values << tuple
      else
        @{{wherish.id}}_values << tuple
      end

      @last_wherish_clause = :{{wherish.id}}

      self
    end

    # Add `{{wherish.upcase.id}}` clauses just like `#{{wherish.id}}`.
    def and_{{wherish.id}}(clause : String, params : Array? = nil)
      {{wherish.id}}(clause, params)
    end

    # Add `{{wherish.upcase.id}}` clauses just like `#or_{{wherish.id}}`.
    def or_{{wherish.id}}(clause : String, params : Array? = nil)
      {{wherish.id}}(clause, params, or: true)
    end

    # :nodoc:
    def self.{{wherish.id}}(clause : String, params : Array? = nil)
      new.{{wherish.id}}(clause, params)
    end

    # :nodoc:
    def self.and_{{wherish.id}}(clause : String, params : Array? = nil)
      new.and_{{wherish.id}}(clause, params)
    end

    # :nodoc:
    def self.or_{{wherish.id}}(clause : String, params : Array? = nil)
      new.and_{{wherish.id}}(clause, params, or: true)
    end

    # A convenient way to add `{{wherish.upcase.id}}` clauses. Multiple clauses in a single call are joined with `AND`. Examples:
    #
    # ```
    # user = User.new(id: 42)
    # query = Query(Post).new
    #
    # # All clauses below will result in
    # # "{{wherish.upcase.id}} (posts.author_id = ?)"
    # # with params [42]
    # query.{{wherish.id}}(author: user)
    # query.{{wherish.id}}(author_id: user.id)
    # query.{{wherish.id}}("posts.author_id = ?", [user.id])
    #
    # # Will result in
    # # "{{wherish.upcase.id}} (posts.author_id IN (?, ?) AND popular = ?)"
    # # with params [1, 2, true]
    # query.{{wherish.id}}(author_id: [1, 2], popular: true)
    #
    # # Will result in
    # # "{{wherish.upcase.id}} (posts.author_id = ? AND editor_id IS NULL)"
    # # with params [42]
    # query.{{wherish.id}}(author: user, editor: nil)
    #
    # # Will result in
    # # "{{wherish.upcase.id}} (posts.author_id = ?) AND (editor_id IS NOT NULL)"
    # # with params [42]
    # query.{{wherish.id}}(author: user).{{wherish.id}}(editor: !nil)
    #
    # # Will result in
    # # "{{wherish.upcase.id}} (users.role = ?)"
    # # with params [1]
    # Query(User).new.{{wherish.id}}(role: User::Role::Admin)
    # ```
    def {{wherish.id}}(**{{wherish.id}}, or = false)
      group = [] of {{wherish.capitalize.id}}Tuple
      {{wherish.id}}.to_h.tap &.each do |key, value|
        if value.is_a?(Core::Model)
          reference_key = ModelType.reference_key(key) rescue nil
          if reference_key
            column_name = ModelType.table_name + "." + reference_key.to_s
            if value.nil?
              group << {{wherish.capitalize.id}}Tuple.new(
                clause: column_name + " IS NULL",
                params: nil,
              )
            else
              group << {{wherish.capitalize.id}}Tuple.new(
                clause: column_name + " = ?",
                params: prepare_params([value.primary_key_value]),
              )
            end
          else
            raise ArgumentError.new("Invalid reference key \"#{key}\" in {{wherish.id}} clause")
          end
        elsif ModelType.db_fields.keys.includes?(key)
          if value.nil?
            group << {{wherish.capitalize.id}}Tuple.new(
              clause: key.to_s + " IS NULL",
              params: nil,
            )
          elsif value.is_a?(Array)
            group << {{wherish.capitalize.id}}Tuple.new(
              clause: key.to_s + " IN (" + value.size.times.map { "?" }.join(", ") + ")",
              params: prepare_params(value),
            )
          else
            if value == true && ModelType.db_fields[key] != Bool
              group << {{wherish.capitalize.id}}Tuple.new(
                clause: key.to_s + " IS NOT NULL",
                params: nil,
              )
            else
              group << {{wherish.capitalize.id}}Tuple.new(
                clause: key.to_s + " = ?",
                params: prepare_params([value]),
              )
            end
          end
        else
          raise ArgumentError.new("A key must be either reference or a field! Given: #{key}")
        end
      end

      {{wherish.id}}(group.map(&.[:clause]).join(" AND "), group.map(&.[:params]).flatten, or: or)

      self
    end

    # Equals to `#{{wherish.id}}`.
    def and_{{wherish.id}}(**{{wherish.id}})
      {{wherish.id}}(**{{wherish.id}}, or: false)
    end

    # :nodoc:
    def self.{{wherish.id}}(**{{wherish.id}})
      new.{{wherish.id}}(**{{wherish.id}})
    end

    # :nodoc:
    def self.and_{{wherish.id}}(**{{wherish.id}})
      new.and_{{wherish.id}}(**{{wherish.id}})
    end

    # A convenient way to add `OR {{wherish.upcase.id}}` clauses. Multiple clauses in a single call are joined with `AND`. See `#{{wherish.id}}` for examples.
    def or_{{wherish.id}}(**{{wherish.id}})
      {{wherish.id}}(**{{wherish.id}}, or: true)
    end

    # :nodoc:
    def self.or_{{wherish.id}}(**{{wherish.id}})
      new.{{wherish.id}}(**{{wherish.id}}, or: true)
    end

    # :nodoc:
    macro {{wherish.id}}_clause
      {{wherish.id}}_clause_used = false

      if {{wherish.id}}_values.any?
        unless {{wherish.id}}_clause_used
          query += " " + {{wherish.upcase}} + " "
          {{wherish.id}}_clause_used = true
        end

        query += {{wherish.id}}_values.map(&.[:clause]).join(" AND ") { |w| "(#{w})" }
        params.concat({{wherish.id}}_values.map(&.[:params]).flatten.compact)
      end

      if or_{{wherish.id}}_values.any?
        if {{wherish.id}}_clause_used
          query += " OR "
        else
          query += " " + {{wherish.upcase}} + " "
        end

        query += or_{{wherish.id}}_values.map(&.[:clause]).join(" OR ") { |w| "(#{w})" }
        params.concat(or_{{wherish.id}}_values.map(&.[:params]).flatten.compact)
      end
    end
  {% end %}

  {% for x in %w(and or) %}
    # A shorthand for calling `{{x.id}}_where` or `{{x.id}}_having` depending on the last clause call.
    #
    # ```
    # query.where(foo: "bar").{{x.id}}(baz: "qux")
    # # => WHERE (foo = 'bar') {{x.upcase.id}} (baz = 'qux')
    # query.having(foo: "bar").{{x.id}}(baz: "qux")
    # # => HAVING (foo = 'bar') {{x.upcase.id}} (baz = 'qux')
    # ```
    def {{x.id}}(**args)
      case @last_wherish_clause
      when :having
        {{x.id}}_having(**args)
      else
        {{x.id}}_where(**args)
      end
    end

    # A shorthand for calling `{{x.id}}_where` or `{{x.id}}_having` depending on the last clause call.
    #
    # ```
    # query.where(foo: "bar").{{x.id}}("created_at > NOW()")
    # # => WHERE (foo = 'bar') {{x.upcase.id}} (created_at > NOW())
    # query.having(foo: "bar").{{x.id}}("created_at > NOW()")
    # # => HAVING (foo = 'bar') {{x.upcase.id}} (created_at > NOW())
    # ```
    def {{x.id}}(clause, params = nil)
      case @last_wherish_clause
      when :having
        {{x.id}}_having(clause, params)
      else
        {{x.id}}_where(clause, params)
      end
    end
  {% end %}

  # TODO: Remove when `DBValue` includes `Enum`.
  protected def prepare_params(params)
    params.try &.map do |p|
      if p.is_a?(Enum)
        p.value.as(DBValue)
      else
        p.as(DBValue)
      end
    end
  end
end
