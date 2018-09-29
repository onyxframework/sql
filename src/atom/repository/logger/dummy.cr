require "../logger"

# Does not log anything.
class Atom::Repository::Logger::Dummy < Atom::Repository::Logger
  # Does nothing except yielding the *block*.
  def wrap(data_to_log : String, &block)
    yield
  end
end
