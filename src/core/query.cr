require "./query/*"

module Core
  # A powerful and type-safe SQL Query builder. Can be used either as a separate struct:
  #
  # ```
  # Core::Query(Post).new.where(id: 42)
  # ```
  #
  # or like an included module (included by default in `Core::Schema`):
  #
  # ```
  # Post.where(id: 42)
  # ```
  #
  # Queries can be either select (default), insert, update or delete, just like an actual SQL query.
  # Query calls are chainable: `Post.where(id: 42).join(:author).select('*')`.
  #
  # Call `#to_s` to build up the Query into SQL String. `#params` are filled up while building.
  struct Query(T)
    # Possible query SQL types.
    enum Type
      Insert
      Select
      Update
      Delete
    end

    # This query `Type`.
    property type : Type = :select

    # Mark this query as update one. Call `#set` afterwards.
    def update
      self.type = :update
      self
    end

    # Mark this query as delete one. You may want to call `#where` afterwards.
    def delete
      self.type = :delete
      self
    end

    # An array of DB params for this query. It's filled up only after `#to_s` call.
    getter params : Array(DB::Any | Array(DB::Any)) | Nil = nil

    # Duplicates this query.
    def dup
      dup = self.class.new

      {% for m in %w(group_by having insert join limit offset order_by returning select set where) %}
        dup.{{m.id}} = @{{m.id}}.dup
      {% end %}

      return dup
    end

    # Alias of `#limit(nil)`.
    def all
      limit(nil)
    end

    # Alias of `#limit(1)`.
    def one
      limit(1)
    end

    # Alias of `#order_by(T.primary_key, :asc).one`.
    def first
      order_by(T.primary_key, :asc).one
    end

    # Alias of `#order_by(T.primary_key, :desc).one`.
    def last
      order_by(T.primary_key, :desc).one
    end

    # Build this query into plain SQL string. `#params` are set after the query is built.
    #
    # Depending on query `#type`, a list blocks to append differs:
    #
    # - Insert query would append `#insert` and `#returning` clauses
    # - Select query would append `#select`, `#join`, `#where`, `#group_by`, `#having`, `#order_by`, `#limit` and `#offset` clauses
    # - Update query would append `#set`, `#where` and `#returning` clauses
    # - Delete query would append `#where` and `#returning` clauses
    #
    # NOTE: When calling `Core::Repository#exec` with insert, update or delete query, its `#returning` is forced to be `nil`. Similarly, when calling `Core::Repository#query` with insert, update or delete query, `#returning` is called with `'*'` if not set before.
    def to_s
      unless @params.nil?
        @params.not_nil!.clear
      end

      query = ""

      case type
      when Type::Insert
        query += "INSERT INTO #{T.table}"
        append_insert(query)
        append_returning(query)
      when Type::Select
        append_select(query)
        query += " FROM #{T.table}"
        append_join(query)
        append_where(query)
        append_group_by(query)
        append_having(query)
        append_order_by(query)
        append_limit(query)
        append_offset(query)
      when Type::Update
        query += "UPDATE #{T.table} SET"
        append_set(query)
        append_where(query)
        append_returning(query)
      when Type::Delete
        query += "DELETE FROM #{T.table}"
        append_where(query)
        append_returning(query)
      end

      query.strip
    end

    protected def ensure_params
      @params = Array(DB::Any | Array(DB::Any)).new if @params.nil?
      @params.not_nil!
    end

    # Which clause - `WHERE` or `HAVING` was called the latest?
    # :nodoc:
    enum LatestWherishClause
      Where
      Having
    end

    @latest_wherish_clause : LatestWherishClause = :where

    {% for joinder in %w(and or) %}
      {% for not in [true, false] %}
        # A shorthand for calling `{{joinder.id}}_where{{"_not".id if not}}` or `{{joinder.id}}_having{{"_not".id if not}}` depending on the latest call.
        def {{joinder.id}}{{"_not".id if not}}(**args : **T) forall T
          if @latest_wherish_clause == LatestWherishClause::Having
            raise "Cannot call 'Core::Query(T)#having with named arguments'"
          else
            {{joinder.id}}_where{{"_not".id if not}}(**args)
          end
        end

        # :nodoc:
        def {{joinder.id}}{{"_not".id if not}}(clause : String, *params)
          if @latest_wherish_clause == LatestWherishClause::Having
            {{joinder.id}}_having{{"_not".id if not}}(clause, *params)
          else
            {{joinder.id}}_where{{"_not".id if not}}(clause, *params)
          end
        end

        # :nodoc:
        def {{joinder.id}}{{"_not".id if not}}(clause : String)
          if @latest_wherish_clause == LatestWherishClause::Having
            {{joinder.id}}_having{{"_not".id if not}}(clause)
          else
            {{joinder.id}}_where{{"_not".id if not}}(clause)
          end
        end
      {% end %}
    {% end %}
  end
end
