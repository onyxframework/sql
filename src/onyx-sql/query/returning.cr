module Onyx::SQL
  class Query(T)
    # Add `RETURNING` clause by either model field or reference or explicit Char or String.
    #
    # NOTE: All `RETURNING` clauses are removed on `Repository#exec(query)` call.
    # NOTE: SQLite does **not** support `RETURNING` clause.
    #
    # ```
    # q = user.insert.returning(:id, :name)
    # q.build # => {"INSERT INTO users ... RETURNING id, name"}
    #
    # q = user.insert.returning("foo")
    # q.build # => {"INSERT INTO users ... RETURNING foo"}
    # ```
    def returning(values : Enumerable(T::Field | T::Reference | Char | String))
      values.each do |value|
        {% begin %}
          {% table = T.annotation(Model::Options)[:table] %}

          if value.is_a?(T::Field)
            case value
            {% for ivar in T.instance_vars.reject(&.annotation(Reference)) %}
              when .{{ivar.name}}?
                column = T.db_column({{ivar.name.symbolize}})

                ensure_returning << if @alias
                  "#{@alias}.#{column}"
                else
                  "{{table.id}}.#{column}"
                end
            {% end %}
            else
              raise "BUG: #{value} didn't match any of #{T} instance variables"
            end
          elsif value.is_a?(T::Reference)
            case value
            {% for ivar in T.instance_vars.select(&.annotation(Reference)).reject(&.annotation(Reference)[:foreign_key]) %}
              when .{{ivar.name}}?
                column = T.db_column({{ivar.name.symbolize}})

                ensure_returning << if @alias
                  "#{@alias}.#{column}"
                else
                  "{{table.id}}.#{column}"
                end
            {% end %}
            else
              raise "BUG: #{value} didn't match any of #{T} instance variables"
            end
          else
            ensure_returning << value.to_s
          end
        {% end %}
      end

      self
    end

    # ditto
    def returning(*values : T::Field | T::Reference | Char | String)
      returning(values)
    end

    # Add `RETURNING` asterisk clause for the whole `T` table.
    #
    # NOTE: All `RETURNING` clauses are removed on `Repository#exec(query)` call.
    # NOTE: SQLite does **not** support `RETURNING` clause.
    #
    # ```
    # Post.returning(Post) # => RETURNING posts.*
    # ```
    def returning(klass : T.class)
      ensure_returning << if @alias
        "#{@alias}.*"
      else
        {{T.annotation(Model::Options)[:table].id.stringify}} + ".*"
      end

      self
    end

    # Add `RETURNING` asterisk clause for the whole `T` table and optionally *values*.
    #
    # NOTE: All `RETURNING` clauses are removed on `Repository#exec(query)` call.
    # NOTE: SQLite does **not** support `RETURNING` clause.
    #
    # ```
    # Post.returning(Post, :id) # => RETURNING posts.*, posts.id
    # ```
    def returning(klass : T.class, *values : T::Field | T::Reference | Char | String)
      ensure_returning << if @alias
        "#{@alias}.*"
      else
        {{T.annotation(Model::Options)[:table].id.stringify}} + ".*"
      end

      unless values.empty?
        returning(values)
      end

      self
    end

    @returning : Deque(String)? = nil
    protected property returning

    protected def get_returning
      @returning
    end

    protected def ensure_returning
      @returning ||= Deque(String).new
    end

    protected def append_returning(sql, *args)
      return if @returning.nil? || ensure_returning.empty?

      sql << " RETURNING "

      first = true
      ensure_returning.each do |value|
        sql << ", " unless first; first = false
        sql << value
      end
    end
  end
end
