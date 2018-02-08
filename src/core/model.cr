require "./model/schema"
require "./model/validation"

module Core
  # A `Model` is a Crystal object with properties.
  # It may be mapped from database, but it doesn't have logic to interact with a database itself.
  # For database communication, please see `Repository`.
  abstract class Model
    include Schema
  end
end
