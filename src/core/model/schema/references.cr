module Core
  abstract class Model
    module Schema
      # Define a reference.
      #
      # Generates a nilable *name* property, as well as initializers, for example:
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
      # If *key* is given, also generates a field property. Nilability of both reference and field now depends on *class* and *nilable* option; and initializer. Basically, the key should copy one from SQL schema. For example:
      #
      # ```
      # schema do
      #   primary_key :id
      #   reference :referrer, User?, key: :referrer_id # Same as User, nilable: true
      #   reference :creator, User, key: :creator_id
      # end
      #
      # # Will expand in:
      #
      # property referrer : User?
      # property referrer_id : PrimaryKey?
      # property! creator : User?
      # property! creator_id : PrimaryKey?
      #
      # def initialize(
      #                @id : PrimaryKey? = nil,
      #                @referrer : User? = nil,
      #                @creator : User? = nil,
      #                @referrer_id : PrimaryKey? = nil,
      #                @creator_id : PrimaryKey? = nil)
      #   @referrer_id ||= @referrer.try &.id # Smarty!
      #   @creator_id ||= @creator.try &.id
      # end
      # ```
      #
      # A reference's primary key is obtained from the *class* itself, or, if given, from *foreign_key*. But remember that *foreign_key* is needed for `Query#join` and other methods!
      #
      # Another example:
      #
      # ```
      # class User
      #   primary_key :id
      #   reference :referrer, User, key: :referrer_id
      #   reference :referrals, Array(User), foreign_key: :referrer_id
      #   reference :posts, Array(Post), foreign_key: :author_id
      # end
      #
      # class Post
      #   reference :author, User, key: :author_id
      # end
      # ```
      macro reference(name, class klass, key = nil, key_type = nil, foreign_key = nil, nilable = nil)
        {%
          key_nilable = nilable == nil ? "#{klass}".includes?("::Nil") || "#{klass}".ends_with?("?") : nilable

          _type = klass.is_a?(Generic) ? klass.type_vars.first.resolve : klass.resolve
          foreign_key = _type.constant("PRIMARY_KEY")[:name] unless foreign_key

          is_array = klass.is_a?(Generic) ? klass.name.resolve.name == "Array(T)" : false

          INTERNAL__CORE_REFERENCES.push({
            name:        name,
            "class":     klass,
            type:        _type,
            array:       is_array,
            key:         key,
            foreign_key: foreign_key,
          })
        %}

        property{{"!".id if key && !key_nilable}} {{name.id}} : {{klass.id}} | Nil

        {% if key %}
          {% key_type = _type.constant("PRIMARY_KEY")[:type] unless key_type %}
          field({{key}}, {{key_type}}, nilable: {{key_nilable}})
        {% end %}
      end
    end
  end
end
