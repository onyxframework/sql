module Core
  abstract class Model
    # A module containing objects able to map to/from  JSON.
    module Converters::JSON
      # Abstract class for JSON converters.
      #
      # OPTIMIZE: Make class methods abstract. See https://stackoverflow.com/questions/41651107/crystal-abstract-static-method
      abstract class Converter(T)
        def self.to_json(t : T, json)
          raise "Not implemented!"
        end

        def self.from_json(pull_parser) : T
          raise "Not implemented!"
        end
      end
    end
  end
end
