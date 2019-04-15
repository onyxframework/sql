module Onyx::SQL
  class Query(T)
    # Add explicit `SET` *clause* and mark this query as `UPDATE` one.
    #
    # ```
    # query.set("salary = salary * 2")
    # ```
    def set(clause : String)
      ensure_set << Set.new(clause)

      @type = :update
      self
    end

    # Add explicit `SET` *clause* with *params* and mark this query as `UPDATE` one.
    #
    # ```
    # query.set("salary = salary * ?", 2)
    # ```
    def set(clause : String, *params : DB::Any)
      ensure_set << Set.new(
        clause: clause,
        explicit: false,
        values: params,
      )

      @type = :update
      self
    end

    # Add `SET` clauses from *values* and mark this query as `UPDATE` one.
    # It's a **type-safe** method.
    # However, it will call `.not_nil!` on references' primary keys, thus it can raise
    # `NilAssertionError` in runtime:
    #
    # ```
    # Post.update.set(author: user) # Will raise NilAssertionError in runtime if `user.id` is `nil`
    # ```
    #
    # TODO: Consider updating explicit reference keys instead, e.g.
    # `Post.update.set(author_id: user.id.not_nil!)` (when `Model.db_values` allows to).
    #
    # ## Example:
    #
    # ```
    # query = User.update.set(name: "Jake", age: 17)
    # query.build # => {"UPDATE users SET name = ?, age = ?", {"Jake", 17}}
    # ```
    def set(**values : **U) : self forall U
      values.each do |key, value|
        {% begin %}
          case key
          {% for key, value in U %}
            {%
              ivar = T.instance_vars.find(&.name.== key)
              raise "Cannot find an instance variable named @#{key} in #{T}" unless ivar

              not_null = (a = ivar.annotation(Field) || ivar.annotation(Reference)) && a[:not_null]

              raise "On Query(#{T})#set: #{key} is nilable in compilation time (`#{value}`), but #{T}@#{ivar.name} has `not_null` option set to `true`. Consider calling `.not_nil!` on the value" if not_null && value.nilable?

              if (a = ivar.annotation(Reference)) && a[:foreign_key]
                raise <<-TEXT
                \e[41m Onyx::SQL compilation error \e[0m — Must not update \e[33m\e[1mUser@foo\e[0m in a query, because it's a foreign reference
                TEXT
              end
            %}

            when {{key.symbolize}}
              ensure_set << Set.new(
                clause: T.db_column({{ivar.name.symbolize}}),
                explicit: true,
                values: T.db_values({{ivar.name}}: value.as({{value}})).to_a
              )
          {% end %}
          else
            raise "BUG: Runtime case didn't match anything"
          end
        {% end %}
      end

      @type = :update
      self
    end

    @set : Deque(Set)? = nil

    protected def get_set
      @set
    end

    private struct Set
      getter clause, values
      getter? explicit

      def initialize(@clause : String, @explicit : Bool = false, @values : Enumerable(DB::Any)? = nil)
      end
    end

    protected def ensure_set
      @set ||= Deque(Set).new
    end

    protected def append_set(sql, params, params_index)
      raise "No values to SET in the UPDATE query" if ensure_set.empty?

      sql << " SET "

      first = true
      ensure_set.each do |set|
        sql << ", " unless first; first = false
        sql << set.clause

        if set.explicit?
          values = set.values
          raise "BUG: Nil values for explicit set" unless values
          raise "BUG: Explicit set values size != 1 (got #{values.size} instead)" unless values.size == 1

          sql << " = " << (params_index ? "$#{params_index.value += 1}" : '?')
          params.try &.push(values.first)
        else
          set.values.try &.each do |value|
            params.try &.push(value)
          end
        end
      end
    end
  end
end
