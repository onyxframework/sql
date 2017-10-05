require "./converter"

module Core
  abstract class Model
    module Converters::DB
      # Allows to represent `INT` values as `::Enum`s in `Model`s.
      #
      # ```
      # # SQL:
      # # table users
      # #   column role INT
      #
      # class User < Core::Model
      #   enum Role
      #     JustAUser
      #     Admin
      #   end
      #
      #   schema do
      #     field :role, Role, db_converter: Converters::DB::Enum
      #   end
      # end
      #
      # user.role   # => User::Role::Admin
      # user.insert # => INSERT INTO users (role) VALUES(1)
      # ```
      #
      # NOTE: This converter is **automatically** applied for to `::Enum` fields.
      class Enum(EnumClass) < Converter(Enum)
        def self.from_rs(rs)
          EnumClass.new(rs.read(Int32))
        end
      end
    end
  end
end
