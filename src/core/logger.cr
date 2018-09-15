# Logs back-end requests (presumably from `Repository`).
abstract class Core::Logger
  abstract def wrap(data_to_log : String, &block)
end
