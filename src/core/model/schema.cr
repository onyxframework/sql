require "db"
require "../primary_key"
require "./schema/*"

module Core
  abstract class Model
    # Schema defines Database mapping and model fields. It allows `Repository` and `Query` to work with this model.
    #
    # ```
    # class User < Core::Model
    #   schema "users" do
    #     primary_key :id
    #     reference :referrer, self, key: :referrer_id
    #     reference :referrals, self, foreign_key: :referrer_id
    #     reference :posts, Post, foreign_key: :author_id
    #     field :name, String
    #     field :age, Int32?
    #     created_at_field :created_at
    #   end
    # end
    #
    # class Post < Core::Model
    #   schema "posts" do
    #     primary_key :id
    #     reference :author, User, key: :author_id
    #     field :content, String
    #     created_at_field :created_at
    #     updated_at_field :updated_at
    #   end
    # end
    # ```
    module Schema
      # A basic macro for schema definition.
      # All other macros have to be called **within** the *block*.
      # It can only be called **once** per model.
      #
      # ```
      # class User < Core::Model
      #   schema "users" do
      #     primary_key :id
      #   end
      # end
      # ```
      macro schema(table, &block)
        INTERNAL__CORE_FIELDS = [] of NamedTuple
        INTERNAL__CORE_REFERENCES = [] of NamedTuple
        INTERNAL__CORE_CREATED_AT_FIELDS = [] of Symbol
        INTERNAL__CORE_UPDATED_AT_FIELDS = [] of Symbol

        {{yield}}

        define_getters({{table}})
        define_initializer
        define_db_mapping
        define_changes
        define_validation
      end
    end
  end
end
