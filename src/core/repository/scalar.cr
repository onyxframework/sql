module Core
  class Repository
    # Call `db.scalar(sql, *params)`.
    def scalar(sql : String, *params : DB::Any | Array(DB::Any))
      sql = prepare_query(sql)

      @logger.wrap("[#{driver_name}] #{sql}") do
        db.scalar(sql, *params)
      end
    end

    # Call `db.scalar(sql, params)`.
    def scalar(sql : String, params : Enumerable(DB::Any | Array(DB::Any))? = nil)
      sql = prepare_query(sql)

      @logger.wrap("[#{driver_name}] #{sql}") do
        if params
          db.scalar(sql, params.to_a)
        else
          db.scalar(sql)
        end
      end
    end

    # Build *query* and call `db.scalar(query.to_s, query.params)`.
    def scalar(query : Query)
      sql = prepare_query(query.to_s)

      if query.params.try &.any?
        scalar(sql, query.params)
      else
        scalar(sql)
      end
    end
  end
end
