class Atom
  class Repository
    # Call `db.exec(sql, *params)`.
    def exec(sql : String, *params : DB::Any | Array(DB::Any)) : DB::ExecResult
      sql = prepare_query(sql)

      @logger.wrap("[#{driver_name}] #{sql}") do
        db.exec(sql, *params)
      end
    end

    # Call `db.exec(sql, params)`.
    def exec(sql : String, params : Enumerable(DB::Any | Array(DB::Any))? = nil) : DB::ExecResult
      sql = prepare_query(sql)

      @logger.wrap("[#{driver_name}] #{sql}") do
        if params
          db.exec(sql, params.to_a)
        else
          db.exec(sql)
        end
      end
    end

    # Build *query* and call `db.exec(query.to_s, query.params)`.
    def exec(query : Query)
      raise ArgumentError.new("Must not call 'Repository#exec' with SELECT Query. Consider using 'Repository#scalar' or 'Repository#query' instead") if query.type == :select

      # Removes `.returning`, so DB doesn't hang! 🍬
      query.returning = nil
      sql = prepare_query(query.to_s)

      if query.params.try &.any?
        exec(sql, query.params)
      else
        exec(sql)
      end
    end
  end
end
