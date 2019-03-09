module Onyx::SQL::Model
  # `.schema` is a convenient DSL to avoid dealing with cumbersome (but extremely powerful)
  # annotations directly. Consider this code:
  #
  # ```
  # @[Onyx::SQL::Model::Options(table: "users", primary_key: @id)]
  # class User
  #   include Onyx::SQL::Model
  #
  #   property! id : Int32?
  #
  #   @[Onyx::SQL::Field(not_null: true)]
  #   property! username : String
  #
  #   @[Onyx::SQL::Reference(foreign_key: "author_id")]
  #   property! authored_posts : Array(Post)?
  # end
  #
  # @[Onyx::SQL::Model::Options(table: "posts", primary_key: @id)]
  # class Post
  #   include Onyx::SQL::Model
  #
  #   @[Onyx::SQL::Field(converter: PG::Any(Int32))]
  #   property! id : Int32?
  #
  #   @[Onyx::SQL::Field(not_null: true)]
  #   property! content : String?
  #
  #   property cover : String?
  #
  #   @[Onyx::SQL::Reference(key: "author_id", not_null: true)]
  #   property! author : User?
  # end
  # ```
  #
  # With the DSL, it could be simplifed to:
  #
  # ```
  # class User
  #   schema users do
  #     pkey id : Int32
  #     type username : String, not_null: true
  #     type authored_posts : Array(Post), foreign_key: "author_id"
  #   end
  # end
  #
  # class Post
  #   schema posts do
  #     pkey id : Int32
  #     type content : String, not_null: true
  #     type cover : String
  #     type author : User, key: "author_id", not_null: true
  #   end
  # end
  # ```
  #
  # This macro has a single mandatory argument *table*, which is, obviously, the model's table name.
  # The schema currently **requires** a `.pkey` variable.
  #
  # TODO: Make the primary key optional.
  macro schema(table, &block)
    {{yield.id}}
    define_options({{table}})
  end

  # Declare a model field or reference. **Must** be called within `.schema` block.
  # Expands `type` to either nilable `property` or raise-on-nil `property!`, depending on
  # the `not_null` option. The latter would raise in runtime if accessed or tried to
  # be set with the `nil` value.
  #
  # ```
  # class User
  #   include Onyx::SQL::Model
  #
  #   schema users do
  #     pkey id : Int32
  #     type name : String, not_null: true
  #     type age : Int32
  #   end
  # end
  #
  # user = User.new
  #
  # user.id   # => nil
  # user.name # => nil
  # user.age  # => nil
  #
  # user.insert                  # Will raise in runtime, because name is `nil`
  # User.insert(name: user.name) # Safer alternative, would raise in compilation time instead
  #
  # user = User.new(name: "John", age: 18)
  # user.name = nil # Would raise in compilation time, cannot set to `nil`
  # user.age = nil  # OK
  # ```
  macro type(declaration, **options)
    property {{declaration.var}} : {{declaration.type}} | Nil

    macro finished
      {% unless options.empty? %}
        \{%
          type = {{declaration.type}}

          if type.union?
            if type.union_types.size != 2
              raise "Only T | Nil unions can be an Onyx::SQL::Model's variables (got #{type} type for #{@type}@#{declaration.var})"
            end

            type = type.union_types.find { |t| t != Nil }
          end

          if type <= Enumerable
            if type.type_vars.size != 1
              raise "Cannot use #{type} as an Onyx::SQL instance variable for #{@type}"
            end

            type = type.type_vars.first
          end
        %}

        \{% if type < Onyx::SQL::Model %}
          \{{"@[Onyx::SQL::Reference(key: #{{{options[:key]}}}, foreign_key: #{{{options[:foreign_key]}}}, not_null: #{{{options[:not_null]}}})]".id}}
        \{% else %}
          \{{"@[Onyx::SQL::Field(key: #{{{options[:key]}}}, default: #{{{options[:default]}}}, converter: #{{{options[:converter]}}}, not_null: #{{{options[:not_null]}}})]".id}}
        \{% end %}

        @{{declaration.var}} : {{declaration.type}} | Nil{{" = #{declaration.value}".id if declaration.value}}
      {% end %}
    end
  end

  # Declare a model primary key, **must** be called within `.schema` block.
  # It is equal to `.type`, but also passes `not_null: true` and
  # defines the `:primary_key` option for the `Options` annotation.
  # It's currently mandatory to have a primary key in a model, which may change in the future.
  #
  # ```
  # class User
  #   schema users do
  #     pkey id : Int32
  #   end
  # end
  #
  # # Expands to
  #
  # @[Onyx::SQL::Model::Options(primary_key: @id)]
  # class User
  #   @[Onyx::SQL::Field(not_null: true)]
  #   property! id : Int32
  # end
  macro pkey(declaration, **options)
    private ONYX_SQL_MODEL_SCHEMA_PK = {{"@#{declaration.var}".id}}
    type({{declaration}}, not_null: true, {{**options}})
  end

  private macro define_options(table)
    {% raise "Primary key is not defined in #{@type} schema. Use `pkey` macro for this" unless ONYX_SQL_MODEL_SCHEMA_PK %}

    @[Onyx::SQL::Model::Options(table: {{table}}, primary_key: {{ONYX_SQL_MODEL_SCHEMA_PK}})]
    class ::{{@type}}
    end
  end
end
