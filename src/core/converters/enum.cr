require "../converter"

module Core
  module Converters
    # Allows to represent `SMALLINT`, `INT` or `BIGINT` values as Enums in models.
    #
    # ```
    # # SQL:
    # # table users
    # #   column role SMALLINT
    #
    # require "core/converters/enum"
    #
    # class User < Core::Model
    #   enum Role
    #     JustAUser
    #     Admin
    #   end
    #
    #   schema do
    #     field :role, Role, converter: Converters::Enum(Role)
    #   end
    # end
    #
    # user.role   # => User::Role::Admin
    # user.insert # => INSERT INTO users (role) VALUES(1)
    # ```
    class Enum(EnumClass) < Converter(Enum)
      def self.from_rs(rs)
        value = rs.read(Int32 | Nil)
        EnumClass.new(value) if value
      end

      def self.to_db(enum _enum : EnumClass)
        _enum.value
      end
    end
  end
end
