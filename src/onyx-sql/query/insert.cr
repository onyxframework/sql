module Onyx::SQL
  class Query(T)
    # Mark this query as `INSERT` one and insert the arguments. It's a **type-safe** method.
    # However, it will call `.not_nil!` on references' primary keys, thus it can raise
    # `NilAssertionError` in runtime:
    #
    # ```
    # Post.insert(content: "foo", author: user) # Will raise NilAssertionError in runtime if `user.id` is `nil`
    # ```
    #
    # TODO: Consider inserting explicit reference keys instead, e.g.
    # `Post.insert(author_id: user.id.not_nil!)` (when `Model.db_values` allows to).
    #
    # ## Example:
    #
    # ```
    # query = User.insert(name: "John", age: 18)
    # query.build # => {"INSERT INTO users (name, age) VALUES (?, ?)", {"John", 18}}
    # ```
    #
    # `Model`s have a handy `Model#insert` shortcut. But it is less type-safe (regarding to
    # `not_null` variables, see in `Model#insert` docs):
    #
    # ```
    # user.insert == User.insert(id: user.id, name: user.name.not_nil!)
    # ```
    def insert(**values : **U) : self forall U
      values.each do |key, value|
        {% begin %}
          case key
          {% for key, value in U %}
            {%
              ivar = T.instance_vars.find(&.name.== key)

              not_null = (a = ivar.annotation(Field) || ivar.annotation(Reference)) && a[:not_null]
              raise "On Query(#{T})#insert: #{key} is nilable in compilation time (`#{value}`), but #{T}@#{ivar.name} has `not_null` option set to `true`. Consider calling `.not_nil!` on the value" if not_null && value.nilable?

              db_default = (a = ivar.annotation(Field)) && a[:default]
              is_pk = "@#{ivar.name}".id == T.annotation(Model::Options)[:primary_key].id
            %}

            {% raise "Cannot find an instance variable named @#{key} in #{T}" unless ivar %}

            when {{key.symbolize}}
              if !value.nil? || !({{db_default}} || {{is_pk}})
                ensure_insert << Insert.new(
                  T.db_column({{ivar.name.symbolize}}),
                  Box(DB::Any).new(T.db_values({{ivar.name}}: value.as({{value}}))[0]).as(Void*)
                )
              end
          {% end %}
          else
            raise "BUG: Runtime case didn't match anything"
          end
        {% end %}
      end

      @type = :insert
      self
    end

    def insert(name : T::Field | T::Reference | String, value : String)
      if name.is_a?(T::Field) || name.is_a?(T::Reference)
        ensure_insert << Insert.new(T.db_column(name), value)
      else
        ensure_insert << Insert.new(name, value)
      end

      @type = :insert
      self
    end

    private struct Insert
      getter column, value

      def initialize(@column : String, @value : Void* | String)
      end
    end

    @insert : Deque(Insert)? = nil

    protected def get_insert
      @insert
    end

    protected def ensure_insert
      @insert ||= Deque(Insert).new
    end

    protected def append_insert(sql, params, params_index)
      raise "BUG: Empty @insert" if ensure_insert.empty?

      {% begin %}
        {% table = T.annotation(Model::Options)[:table] %}
        sql << "INSERT INTO " << (@alias || {{table.id.stringify}}) << " ("
      {% end %}

      values_sql = IO::Memory.new

      first = true
      ensure_insert.each do |insert|
        unless first
          sql << ", "
          values_sql << ", "
        end; first = false

        sql << insert.column

        if value = insert.value.as?(Void*)
          values_sql << (params_index ? "$#{params_index.value += 1}" : "?")
          params.not_nil!.push(Box(DB::Any).unbox(value)) if params
        else
          values_sql << insert.value.as(String)
        end
      end

      sql << ") VALUES (" << values_sql << ")"
    end
  end
end
