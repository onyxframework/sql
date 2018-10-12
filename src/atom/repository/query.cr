class Atom
  class Repository
    # Call `db.query(sql, *params)`.
    def query(sql : String, *params : DB::Any | Array(DB::Any))
      sql = prepare_query(sql)

      @logger.wrap("[#{driver_name}] #{sql}") do
        db.query(sql, *params)
      end
    end

    # Call `db.query(sql, params)`.
    def query(sql : String, params : Enumerable(DB::Any | Array(DB::Any))? = nil)
      sql = prepare_query(sql)

      @logger.wrap("[#{driver_name}] #{sql}") do
        if params
          db.query(sql, params.to_a)
        else
          db.query(sql)
        end
      end
    end

    # Call `db.query(sql, *params)` and map the result to `Array(T)`.
    def query(klass : T.class, sql : String, *params : DB::Any | Array(DB::Any)) : Array(T) forall T
      rs = query(sql, *params)

      @logger.wrap("[map] #{{{T.name.stringify}}}") do
        T.from_rs(rs)
      end
    end

    # Call `db.query(sql, params)` and map the result to `Array(T)`.
    def query(klass : T.class, sql : String, params : Enumerable(DB::Any | Array(DB::Any))? = nil) : Array(T) forall T
      rs = query(sql, params)

      @logger.wrap("[map] #{{{T.name.stringify}}}") do
        T.from_rs(rs)
      end
    end

    # Build *query*, call `db.query(sql, params)` and map the result it to `Array(T)` afterwards.
    def query(query : Query(T)) : Array(T) forall T
      # Adds `.returning('*')` if forgot to, so DB doesn't hang! 🍬
      query.returning = ['*'.as(String | Char)] if query.type != :select && query.returning.nil?
      sql = query.to_s

      if query.params.try &.any?
        query(T, sql, query.params)
      else
        query(T, sql)
      end
    end
  end
end
