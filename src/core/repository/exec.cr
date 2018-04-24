class Core::Repository
  module Exec
    # Execute *query* and return a `DB::ExecResult`.
    #
    # See http://crystal-lang.github.io/crystal-db/api/0.5.0/DB/QueryMethods.html#exec%28query%2C%2Aargs%29-instance-method
    #
    # ```
    # repo.exec("UPDATE foo SET now = NOW()")
    # ```
    def exec(query : String, *params)
      query = prepare_query(query)
      params = Core.prepare_params(*params) if params.any?

      query_logger.wrap(query) do
        db.exec(query, *params)
      end
    end

    # Execute *query* (after stringifying and extracting params) and return a `DB::ExecResult`.
    def exec(query : Core::Query::Instance(T)) forall T
      exec(query.to_s, query.params)
    end
  end
end
