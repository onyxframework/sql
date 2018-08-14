require "../converter"

module Core
  module Converters
    # Allows to represent integer values as Enums in models.
    #
    # ```
    # # SQL:
    # # table users
    # #   column role SMALLINT
    #
    # require "core/converters/enum"
    #
    # class User
    #   include Core::Schema
    #
    #   enum Role
    #     JustAUser
    #     Admin
    #   end
    #
    #   schema do
    #     field :role, Role, converter: Core::Converters::Enum(Role)
    #   end
    # end
    #
    # user.role   # => User::Role::Admin
    # user.insert # => INSERT INTO users (role) VALUES(1)
    # ```
    class Enum(EnumClass) < Converter(Enum)
      def self.from_rs(rs)
        rs.read(Int16 | Int32 | Int64 | Nil).try { |v| EnumClass.new(v.to_i32) }
      end

      def self.to_db(enum _enum : EnumClass)
        _enum.value
      end
    end
  end
end
