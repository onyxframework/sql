require "../logger"

# Does not log anything.
class Core::Logger::Dummy < Core::Logger
  # Does nothing except yielding the *block*.
  def wrap(data_to_log : String, &block)
    yield
  end
end
