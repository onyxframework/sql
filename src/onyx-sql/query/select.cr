module Onyx::SQL
  class Query(T)
    # Add `SELECT` clause by either model field or reference or explicit Char or String.
    #
    # If no `#select` is called on a query, then it would select the whole table (`"table.*"`).
    #
    # ```
    # q = User.all
    # q.build # => {"SELECT users.* FROM users"}
    #
    # q = User.select(:id, :name)
    # q.build # => {"SELECT users.id, users.name FROM users"}
    #
    # q = User.select("foo")
    # q.build # => {"SELECT foo FROM users"}
    # ```
    def select(values : Enumerable(T::Field | T::Reference | Char | String))
      values.each do |value|
        {% begin %}
          {% table = T.annotation(Model::Options)[:table] %}

          if value.is_a?(T::Field)
            case value
            {% for ivar in T.instance_vars.reject(&.annotation(Reference)) %}
              when .{{ivar.name}}?
                column = T.db_column({{ivar.name.symbolize}})

                ensure_select << if @alias
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

                ensure_select << if @alias
                  "#{@alias}.#{column}"
                else
                  "{{table.id}}.#{column}"
                end
            {% end %}
            else
              raise "BUG: #{value} didn't match any of #{T} instance variables"
            end
          else
            ensure_select << value.to_s
          end
        {% end %}
      end

      @type = :select
      self
    end

    # ditto
    def select(*values : T::Field | T::Reference | Char | String)
      self.select(values)
    end

    # Add `SELECT` asterisk clause for the whole `T` table.
    #
    # ```
    # Post.select(Post, :id) # => SELECT posts.*, posts.id
    # ```
    def select(klass : T.class)
      ensure_select << if @alias
        "#{@alias}.*"
      else
        {{T.annotation(Model::Options)[:table].stringify}} + ".*"
      end

      @type = :select
      self
    end

    # Add `SELECT` asterisk clause for the whole `T` table and *values*.
    #
    # ```
    # Post.select(Post, :id) # => SELECT posts.*, posts.id
    # ```
    def select(klass : T.class, *values : T::Field | T::Reference | Char | String)
      ensure_select << if @alias
        "#{@alias}.*"
      else
        {{T.annotation(Model::Options)[:table].stringify}} + ".*"
      end

      unless values.empty?
        self.select(values)
      end

      @type = :select
      self
    end

    @select : Deque(String)? = nil

    protected def get_select
      @select
    end

    protected def ensure_select
      @select = Deque(String).new if @select.nil?
      @select.not_nil!
    end

    protected def append_select(sql, *args)
      if selects = @select
        sql << "SELECT "

        first = true
        selects.each do |s|
          sql << ", " unless first; first = false
          sql << s
        end
      else
        sql << "SELECT " << (@alias || {{T.annotation(Model::Options)[:table].id.stringify}}) << ".*"
      end

      sql << " FROM " << (@alias || {{T.annotation(Model::Options)[:table].id.stringify}})
    end
  end
end
