module Core
  abstract class Model
    # A module containing objects able to map from  DB.
    module Converters::DB
      # Abstract class for JSON converters.
      #
      # OPTIMIZE: Make class methods abstract. See https://stackoverflow.com/questions/41651107/crystal-abstract-static-method
      abstract class Converter(T)
        def self.from_rs(rs) : T
          raise "Not implemented!"
        end
      end
    end
  end
end
