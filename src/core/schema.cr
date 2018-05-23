require "db"
require "./primary_key"
require "./validation"
require "./schema/*"

module Core
  # Schema defines Database mapping and model fields. It allows `Repository` and `Query` to work with this model.
  #
  # ```
  # class User
  #   include Core::Schema
  #
  #   schema "users" do
  #     primary_key :id
  #     reference :referrer, self, key: :referrer_id
  #     reference :referrals, self, foreign_key: :referrer_id
  #     reference :posts, Post, foreign_key: :author_id
  #     field :name, String
  #     field :age, Int32?
  #     field :created_at, Time, db_default: true
  #   end
  # end
  #
  # class Post
  #   include Core::Schema
  #
  #   schema "posts" do
  #     primary_key :id
  #     reference :author, User, key: :author_id
  #     field :content, String
  #     field :created_at, Time, db_default: true
  #     field :updated_at, Time?
  #   end
  # end
  # ```
  module Schema
    # A basic macro for schema definition.
    # All other macros have to be called **within** the *block*.
    # It can only be called **once** per model.
    #
    # ```
    # class User
    #   include Core::Schema
    #
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

      {% if @type < Core::Validation %}
        define_validation
      {% end %}
    end
  end
end
