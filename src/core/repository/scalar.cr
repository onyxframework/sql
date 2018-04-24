class Core::Repository
  module Scalar
    # Execute *query* and return a single scalar value.
    #
    # See http://crystal-lang.github.io/crystal-db/api/0.5.0/DB/QueryMethods.html#scalar%28query%2C%2Aargs%29-instance-method
    #
    # ```
    # repo.scalar("SELECT 1").as(Int32)
    # ```
    def scalar(query : String, *params)
      query = prepare_query(query)
      params = Core.prepare_params(*params) if params.any?

      query_logger.wrap(query) do
        db.scalar(query, *params)
      end
    end

    # Execute *query* (after stringifying and extracting params) and return a single scalar value.
    def scalar(query : Core::Query::Instance(T)) forall T
      scalar(query.to_s, query.params)
    end
  end
end
