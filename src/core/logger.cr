# Logs stuff.
abstract class Core::Logger
  abstract def wrap(query : String, &block : String -> _)
end
