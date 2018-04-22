require "../logger"

# Does not log queries.
class Core::Logger::Dummy < Core::Logger
  # Wrap a query.
  def wrap(query : String, &block : String -> _)
    yield query
  end
end
