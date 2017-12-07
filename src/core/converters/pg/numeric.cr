require "../../converter"
require "pg/numeric"

module Core
  module Converters::PG
    # Allows to represent `PG::Numeric` values as `Float64`s in models.
    #
    # ```
    # # SQL:
    # # table users
    # #   column balance NUMERIC(16, 8)
    #
    # require "core/converters/pg/numeric"
    #
    # class User < Core::Model
    #   schema do
    #     field :balance, Float64, converter: Converters::PG::Numeric
    #   end
    # end
    #
    # user = repository.query(Query(User).last).first
    # user.balance # => 42.0
    # ```
    class Numeric < Converter(Float64)
      def self.from_rs(rs)
        rs.read(::PG::Numeric | Nil).try &.to_f64
      end

      def self.to_db(f : Float64)
        f
      end
    end
  end
end
