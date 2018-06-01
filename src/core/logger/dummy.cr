require "../logger"

# Does not log queries.
class Core::Logger::Dummy < Core::Logger
  def wrap(query : String, &block : String -> _)
    yield query
  end
end
