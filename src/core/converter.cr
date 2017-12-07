require "db"

module Core
  # Abstract class for `DB -> Model` converters.
  #
  # OPTIMIZE: Make class methods abstract. See https://stackoverflow.com/questions/41651107/crystal-abstract-static-method
  abstract class Converter(T)
    def self.from_rs(rs) : T
      raise "Not implemented!"
    end

    def self.to_db(i : T) : DB::Any
      raise "Not implemented!"
    end
  end
end
