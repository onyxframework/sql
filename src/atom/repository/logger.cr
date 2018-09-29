# Logs back-end requests (presumably from `Repository`).
abstract class Atom::Repository::Logger
  abstract def wrap(data_to_log : String, &block)
end

require "./logger/*"
