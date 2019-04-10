require "./ext/enumerable/bulk_query"
require "./bulk_query/*"

module Onyx::SQL
  # Bulk query builder.
  # It allows to `#insert` and `#delete` multiple instances in one SQL query.
  # Its API is similar to `Query` — you can `#build` it and turn `#to_s`,
  # as well as pass it to a `Repository`.
  #
  # `Enumerable` is monkey-patched with argless `insert` and `update` methods.
  #
  # ```
  # users = [User.new(name: "Jake"), User.new(name: "John")]
  #
  # query = BulkQuery.insert(users)
  # # Or
  # query = users.insert
  #
  # query.build == {"INSERT INTO users (name) VALUES (?), (?)", ["Jake", "John"]}
  #
  # users = repo.query(users.insert.returning(:id))
  # ```
  class BulkQuery(T)
    # Possible bulk query types. TODO: Add `Update`.
    enum Type
      Insert
      Delete
    end

    # Model instances associated with this query.
    getter instances : Enumerable(T)

    # Query type.
    getter type : Type

    def initialize(@type : Type, @instances)
    end

    # Return the SQL representation of this bulk query. Pass `true` to replace `"?"`
    # query arguments with `"$n"`, which would work for PostgreSQL.
    def to_s(index_params = false)
      io = IO::Memory.new
      to_s(io, params: nil, index_params: index_params)
      io.to_s
    end

    # Put the SQL representation of this bulk query into the *io*.
    # Pass `true` for *index_params* to replace `"?"` query arguments with `"$n"`,
    # which would work for PostgreSQL.
    def to_s(io, index_params = false)
      to_s(io, params: nil, index_params: index_params)
    end

    # Build this bulk query, returning its SQL representation and `Enumerable`
    # of DB-ready params. Pass `true` to replace `"?"` query arguments with `"$n"`,
    # which would work for PostgreSQL.
    def build(index_params = false) : Tuple(String, Enumerable(DB::Any))
      sql = IO::Memory.new
      params = Array(DB::Any).new

      to_s(sql, params, index_params)

      return sql.to_s, params
    end

    protected def to_s(io, params = nil, index_params = false)
      index = index_params ? ParamIndex.new : nil

      case @type
      when Type::Insert
        append_insert(io, params, index)
        append_returning(io, params, index)
      when Type::Delete
        append_delete(io, params, index)
        append_returning(io, params, index)
      end
    end

    private class ParamIndex
      property value = 0
    end
  end
end
