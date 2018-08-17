require "../../converter"

module Core
  module Converters
    # Allows to represent integer array values as Array of Enums in models. You must specify which `Int` you use in the database schema (e.g. `SMALLINT` stays for `Int16`, `INT` for `Int32`).
    #
    # TODO: Remove obstructing `IntClass` requirement. See https://github.com/will/crystal-pg/issues/150
    #
    # ```
    # # SQL:
    # # table users
    # #   column role SMALLINT[]
    #
    # require "core/converters/enum_array"
    #
    # class User
    #   include Core::Schema
    #
    #   enum Permission
    #     CreatePosts
    #     EditPosts
    #   end
    #
    #   schema do
    #     field :permissions, Array(Permission), converter: Core::Converters::EnumArray(Permission, Int16)
    #   end
    # end
    #
    # user.permissions # => [User::Permission::CreatePosts]
    # user.insert      # => INSERT INTO users (permissions) VALUES('{1}')
    # ```
    class EnumArray(EnumClass, IntClass) < Converter(Array(Enum))
      def self.from_rs(rs)
        values = rs.read(Array(IntClass) | Nil)
        values.try &.map { |v| EnumClass.new(v.to_i32) }
      end

      def self.to_db(enum _enum : Array(EnumClass))
        _enum.map(&.value)
      end
    end
  end
end
