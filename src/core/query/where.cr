module Core
  struct Query(T)
    private struct Where
      getter clause, params, or, not

      def initialize(
        @clause : String,
        @params : Array(DB::Any | Array(DB::Any)) | Nil,
        @or : Bool,
        @not : Bool
      )
      end
    end

    @where : Array(Where) | Nil = nil
    protected setter where

    # Add `WHERE` *clause* with *params*.
    #
    # ```
    # query.where("id = ?", 42) # WHERE (id = ?)
    # ```
    #
    # Multiple calls concatenate clauses with `AND`:
    #
    # ```
    # query.where("id = ?", 42).where("foo = ?", "bar")
    # # WHERE (id = ?) AND (foo = ?)
    # ```
    #
    # See also `#and`, `#or`, `#and_where`, `#and_where_not`, `#or_where`, `#or_where_not`.
    def where(clause : String, *params : DB::Any | Array(DB::Any), or : Bool = false, not : Bool = false)
      ensure_where << Where.new(
        clause: clause,
        params: params.to_a.map do |param|
          if param.is_a?(Array)
            param.map(&.as(DB::Any))
          else
            param.as(DB::Any | Array(DB::Any))
          end
        end,
        or: or,
        not: not
      )

      @latest_wherish_clause = :where

      self
    end

    # Add `WHERE` *clause* without params.
    #
    # ```
    # query.where("id = 42") # WHERE (id = 42)
    # ```
    #
    # Multiple calls concatenate clauses with `AND`:
    #
    # ```
    # query.where("id = ?=42").where("foo = 'bar'")
    # # WHERE (id = 42) AND (foo = 'bar')
    # ```
    #
    # See also `#and`, `#or`, `#and_where`, `#and_where_not`, `#or_where`, `#or_where_not`.
    def where(clause : String, or : Bool = false, not : Bool = false)
      ensure_where << Where.new(
        clause: clause,
        params: nil,
        or: or,
        not: not
      )

      @latest_wherish_clause = :where

      self
    end

    # Add `WHERE` clause with named arguments. All clauses in a single call are concatenated with `AND`.
    #
    # Arguments are validated at compilation time. To pass the validation, an argument type must be `<=` compared to the defined attribute type:
    #
    # ```
    # class User
    #   schema users do
    #     type id : Int32
    #     type active : Bool = DB::Default
    #     type age : Int32
    #   end
    # end
    #
    # User.where(active: true, age: 18)
    # # SELECT users.* FROM users WHERE (active = ? AND age = ?)
    #
    # User.where(unknown: "foo") # Compilation time error
    # User.where(age: "foo")     # Compilation time error
    # ```
    #
    # See also `#and`, `#or`, `#and_where`, `#and_where_not`, `#or_where`, `#or_where_not`.
    def where(or : Bool = false, not : Bool = false, **values : **Values) : self forall Values
      {% for key, value in Values %}
        {% found = false %}

        {% for type in (T::CORE_ATTRIBUTES + T::CORE_REFERENCES.select { |t| t["direct"] && !t["enumerable"] }) %}
          {% type = type %} # Say hi to a Crystal bug, "begin" doesn't help :)
          {% value = value %}

          # In cases like `#where(author_id: 42)` check against reference's primary key type
          {% _type = (type["is_reference"] && key.stringify == type["key"]) ? type["reference_type"].constant("PRIMARY_KEY_TYPE") : type["type"] %}

          # First case is `#where(id: 42)` or `#where(author: user)` and the second is `#where(author_id: 42)` mentioned above
          {%
            if key == type["name"] || (key.stringify == type["key"] && type["is_reference"])
              unless value <= _type
                raise "Invalid compile-time type '#{value}' for argument '#{type["name"]}' in 'Query#where' call. Expected: '#{_type}'"
              end

              found = true
            end
          %}
        {% end %}

        {% raise "Class '#{T}' doesn't have an attribute with key '#{key}' defined in its Schema eligible for 'Core::Query(#{T})#where' call" unless found %}
      {% end %}

      {% begin %}
        internal_clauses = uninitialized String[{{Values.size}}]
        internal_params = Array(DB::Any | Array(DB::Any)).new

        values.each_with_index do |key, value, index|
          if value.nil?
            case key
              # where(id: nil) # "WHERE posts.id IS NULL"
              {% for type in T::CORE_ATTRIBUTES.select(&.["key"]) %}
                when {{type["name"].symbolize}}{{", #{type["key"].id.symbolize}".id unless type["name"].stringify == type["key"]}}
                  internal_clauses[index] = "#{T.table}.#{{{type["key"]}}} IS NULL"
              {% end %}

              {% for type in T::CORE_REFERENCES.select { |t| t["direct"] && !t["enumerable"] } %}
                # where(author: nil) # "WHERE posts.author_id IS NULL"
                when {{type["name"].symbolize}}
                  internal_clauses[index] = "#{T.table}.#{{{type["key"]}}} IS NULL"

                # where(author_id: nil) # "WHERE posts.author_id IS NULL"
                when {{type["key"].id.symbolize}}
                  internal_clauses[index] = "#{T.table}.#{{{type["key"]}}} IS NULL"
              {% end %}
            else
              raise "Bug: unexpected key '#{key}'"
            end
          else
            case key
              {% for type in T::CORE_ATTRIBUTES.select(&.["key"]) %}
                # where(id: 42) # "WHERE posts.id = ?", 42
                when {{type["name"].symbolize}}{{", #{type["key"].id.symbolize}".id unless type["name"].stringify == type["key"]}}
                  internal_clauses[index] = "#{T.table}.#{{{type["key"]}}} = ?"

                  internal_params << {% if type["enumerable"] %}
                    value.unsafe_as({{type["true_type"]}}).to_db({{type["true_type"]}})
                  {% else %}
                    value.unsafe_as({{type["true_type"]}}).to_db
                  {% end %}
              {% end %}

              # Only allow direct non-enumerable references
              {% for type in T::CORE_REFERENCES.select { |t| t["direct"] && !t["enumerable"] } %}
                # where(author: user) # "WHERE posts.author_id = ?", user.primary_key
                when {{type["name"].symbolize}}
                  internal_clauses[index] = "#{T.table}.#{{{type["key"]}}} = ?"
                  internal_params << value.unsafe_as({{type["reference_type"]}}).primary_key.to_db

                # where(author_id: 42) # "WHERE posts.author_id = ?", 42
                when {{type["key"].id.symbolize}}
                  {% pk_type = type["reference_type"].constant("PRIMARY_KEY_TYPE") %}

                  internal_clauses[index] = "#{T.table}.#{{{type["key"]}}} = ?"
                  internal_params << value.unsafe_as({{pk_type}}).to_db
              {% end %}
            else
              raise "Bug: unexpected key '#{key}'"
            end
          end
        end

        ensure_where << Where.new(
          clause: internal_clauses.join(" AND "),
          params: internal_params,
          or: or,
          not: not
        )

        @latest_wherish_clause = :where

        self
      {% end %}
    end

    # Add `NOT` *clause* with *params* to `WHERE`.
    #
    # ```
    # where_not("id = ?", 42)
    # # WHERE (...) AND NOT (id = ?)
    # ```
    def where_not(clause, *params)
      where(clause, *params, not: true)
    end

    # Add `NOT` *clause* to `WHERE`.
    #
    # ```
    # where_not("id = 42")
    # # WHERE (...) AND NOT (id = 42)
    # ```
    def where_not(clause)
      where(clause, not: true)
    end

    # Add `NOT` clause with named arguments to `WHERE`.
    #
    # ```
    # where_not(id: 42)
    # # WHERE (...) AND NOT (id = ?)
    # ```
    def where_not(**values)
      where(**values, not: true)
    end

    {% for or in [true, false] %}
      {% for not in [true, false] %}
        # Add `{{or ? "OR".id : "AND".id}}{{" NOT".id if not}}` *clause* with *params* to `WHERE`.
        #
        # ```
        # {{(or ? "or" : "and").id}}_where{{"_not".id if not}}("id = ?", 42)
        # # WHERE (...) {{or ? "OR ".id : "AND ".id}}{{"NOT ".id if not}}(id = ?)
        # ```
        def {{(or ? "or" : "and").id}}_where{{"_not".id if not}}(clause : String, *params)
          where(clause, *params, or: {{or}}, not: {{not}})
        end

        # Add `{{or ? "OR".id : "AND".id}}{{" NOT".id if not}}` *clause* to `WHERE`.
        #
        # ```
        # {{(or ? "or" : "and").id}}_where{{"_not".id if not}}("id = 42")
        # # WHERE (...) {{or ? "OR ".id : "AND ".id}}{{"NOT ".id if not}}(id = 42)
        # ```
        def {{(or ? "or" : "and").id}}_where{{"_not".id if not}}(clause : String)
          where(clause, or: {{or}}, not: {{not}})
        end

        # Add `{{or ? "OR".id : "AND".id}}{{" NOT".id if not}}` clause with named arguments to `WHERE`.
        #
        # ```
        # {{(or ? "or" : "and").id}}_where{{"_not".id if not}}(id: 42)
        # # WHERE (...) {{or ? "OR ".id : "AND ".id}}{{"NOT ".id if not}}(id = ?)
        # ```
        def {{(or ? "or" : "and").id}}_where{{"_not".id if not}}(**values : **T) forall T
          where(**values, or: {{or}}, not: {{not}})
        end
      {% end %}
    {% end %}

    protected def ensure_where
      @where = Array(Where).new if @where.nil?
      @where.not_nil!
    end

    private macro append_where(query)
      unless @where.nil?
        {{query}} += " WHERE "
        first_clause = true

        {{query}} += @where.not_nil!.join(" ") do |clause|
          c = ""
          c += (clause.or ? "OR " : "AND ") unless first_clause
          c += "NOT " if clause.not
          c += "(#{clause.clause})"

          first_clause = false

          unless clause.params.nil?
            ensure_params.concat(clause.params.not_nil!)
          end

          c
        end
      end
    end
  end
end
