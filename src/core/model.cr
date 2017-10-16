require "./model/converters/db/*"
require "./model/converters/json/*"
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
    extend Schema::ClassMethods
    include Validation
  end
end
