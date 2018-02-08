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

    # ditto
    def query_all(model, query, *params)
      query(model, query, *params)
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

    # ditto
    def query_all(query)
      query(query)
    end

    # Query `#db` returning a single *model* instance.
    #
    # ```
    # repo.query_one?(User, "SELECT * FROM users WHERE id = 1") # => User?
    # ```
    def query_one?(model : Model.class, query : String, *params) : Object
      query(model, query, *params).first?
    end

    # Query `#db` returning a model instance inherited from *query*.
    #
    # ```
    # repo.query_one?(Query(User).first) # => User?
    # ```
    def query_one?(query : Core::Query(T)) forall T
      query_one?(T, query.to_s, query.params)
    end

    # Query `#db` returning a single *model* instance. Will raise `NoResultsError` if query returns no instances.
    #
    # ```
    # repo.query_one(User, "SELECT * FROM users WHERE id = 1") # => User
    # ```
    def query_one(model : Model.class, query : String, *params) : Object
      query_one?(model, query, *params) || raise NoResultsError.new(model, query)
    end

    # Query `#db` returning a model instance inherited from *query*. Will raise `NoResultsError` if query returns no instances.
    #
    # ```
    # repo.query_one(Query(User).first) # => User
    # ```
    def query_one(query : Core::Query(T)) forall T
      query_one(T, query.to_s, query.params)
    end

    # Raised if query returns zero model instances.
    class NoResultsError < Exception
      # TODO: Wait for https://github.com/crystal-lang/crystal/issues/5692 to be fixed
      # getter model

      getter query

      def initialize(@model : Model.class, @query : String)
        super("Zero #{@model} instances returned after query \"#{@query}\"")
      end
    end
  end
end
