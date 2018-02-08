class Core::Repository
  module Query
    # Query `#db` returning an array of *model* instances.
    #
    # ```
    # repo.query(User, "SELECT * FROM users") # => Array(User)
    # ```
    #
    # TODO: Handle errors (PQ::PQError)
    def query(model : Model.class, query : String, *params) : Array
      query = prepare_query(query)
      params = Core.prepare_params(*params) if params.any?

      query_logger.wrap(query) do
        db.query_all(query, *params) do |rs|
          rs.read(model)
        end
      end
    end

    # Query `#db` returning an array of model instances inherited from *query*.
    #
    # ```
    # repo.query(Query(User).all) # => Array(User)
    # ```
    #
    # TODO: Handle errors (PQ::PQError)
    def query(query : Core::Query(T)) forall T
      query(T, query.to_s, query.params)
    end
  end
end
