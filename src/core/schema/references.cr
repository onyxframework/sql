module Core
  module Schema
    # Define a reference.
    #
    # Generates an always nilable *name* property, as well as initializers, for example:
    #
    # ```
    # schema do
    #   reference :referrer, User
    #   reference :posts, Array(Post)
    # end
    #
    # # Will expand in:
    #
    # property referrer : User?
    # property posts : Array(Post)?
    #
    # def initialize(@referrer : User? = nil, @posts : Array(Post)? = nil)
    # end
    # ```
    #
    # If *key* is given, also generates a field property. Basically, the key should copy one from SQL schema. For example:
    #
    # ```
    # schema do
    #   primary_key :id
    #   reference :referrer, User, key: :referrer_id
    #   reference :creator, User, key: :creator_id
    # end
    #
    # # Will expand in:
    #
    # property referrer : User?
    # property referrer_id : PrimaryKey?
    # property creator : User?
    # property creator_id : PrimaryKey?
    #
    # def initialize(
    #   @id : PrimaryKey? = nil,
    #   @referrer : User? = nil,
    #   @creator : User? = nil,
    #   @referrer_id : PrimaryKey? = nil,
    #   @creator_id : PrimaryKey? = nil
    # )
    #   @referrer_id ||= @referrer.try &.id # Smarty!
    #   @creator_id ||= @creator.try &.id
    # end
    # ```
    #
    # A reference's primary key is obtained from the *class* itself, or, if given, from *foreign_key*. But remember that *foreign_key* is needed for `Query#join` and other methods!
    #
    # NOTE: For now you have to specify full path to the reference class (with modules)
    #
    # Another example:
    #
    # ```
    # module Models
    #   class User
    #     include Core::Schema
    #
    #     schema "users" do
    #       primary_key :id
    #       reference :referrer, Models::User, key: :referrer_id
    #       reference :referrals, Array(Models::User), foreign_key: :referrer_id
    #       reference :posts, Array(Models::Post), foreign_key: :author_id
    #   end
    #
    #   class Post
    #     include Core::Schema
    #
    #     schema "posts" do
    #       reference :author, Models::User, key: :author_id
    #     end
    #   end
    # end
    # ```
    macro reference(name, class klass, key = nil, key_type = nil, foreign_key = nil)
      {%
        _type = klass.is_a?(Generic) ? klass.type_vars.first : klass
        is_array = klass.is_a?(Generic) ? klass.name.resolve.name == "Array(T)" : false
      %}

      macro finished
        \{%
          foreign_key = {{foreign_key}}.is_a?(NilLiteral) ? {{_type}}.constant("PRIMARY_KEY")[:name] : {{foreign_key}}

          INTERNAL__CORE_REFERENCES.push({
            name:        {{name}},
            "class":     {{klass.stringify}},
            type:        {{_type}},
            array:       {{is_array}},
            key:         {{key}},
            foreign_key: foreign_key,
          })
        %}

        property {{name.id}} : {{klass.id}} | Nil

        \{% if {{key}} %}
          \{% key_type = {{key_type}}.is_a?(NilLiteral) ? {{_type}}.constant("PRIMARY_KEY")[:type] : {{key_type}} %}
          field({{key}}, \{{key_type}}, nilable: true)
        \{% end %}
      end
    end
  end
end
