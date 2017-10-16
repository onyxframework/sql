require "../converter"
require "pg/numeric"

module Core
  abstract class Model
    module Converters::DB
      # Allows to represent `PG::Numeric` values as `Float64`s in `Model`s.
      #
      # ```
      # # SQL:
      # # table users
      # #   column balance NUMERIC(16, 8)
      #
      # require "core/model/converters/db/pg/numeric"
      #
      # class User < Core::Model
      #   schema do
      #     field :balance, Float64, db_converter: Converters::DB::PG::Numeric
      #   end
      # end
      #
      # user = repository.query(Query(User).last).first
      # user.balance # => 42.0
      # ```
      module PG
        class Numeric < Converter(::PG::Numeric)
          def self.from_rs(rs)
            rs.read(::PG::Numeric | Nil).try &.to_f64
          end
        end
      end
    end
  end
end
