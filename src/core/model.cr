require "./model/converters/*"
require "./model/schema"
require "./model/validation"

module Core
  # A `Model` is a pure Crystal object with properties.
  # It may be mapped to/from Database or JSON.
  # It doesn't have a logic to interact with a database itself.
  #
  # For database communication, please see `Repository`.
  abstract class Model
    include Converters
    include Schema
    include Validation
  end
end
