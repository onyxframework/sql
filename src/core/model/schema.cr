require "db"
require "json"

require "../../ext/array"

module Core
  abstract class Model
    # `Schema` allows to define mapping for Database and JSON.
    #
    # A `Model` will have `#from_rs`, `#from_json` and `#to_json` methods after `#schema` is called.
    #
    # It also allows `Repository` and `Query` to work with this `Model`.
    #
    # NOTE: All class and instance methods will be defined on `#schema` macro call if not mentioned another.
    module Schema
      # :nodoc:
      CORE__PRIMARY_KEY_FIELD = uninitialized Symbol
      # :nodoc:
      CORE__PRIMARY_KEY_FIELD_TYPE = uninitialized Object
      # :nodoc:
      CORE__TABLE_NAME = uninitialized String

      # Return table name for this `Model`.
      #
      # ```
      # User.table_name # => "users"
      # ```
      def self.table_name
      end

      # Return a `Hash` of database field keys with their actual values.
      # Does not include virtual fields.
      #
      # ```
      # post = Post.new(author: User.new(id: 42), content: "foo")
      # post.db_fields # => {:author_id => 42, :content => "foo"}
      # ```
      abstract def db_fields

      # Return an array of database field names.
      # Does not include virtual fields.
      #
      # ```
      # User.db_fields # => [:id, :name]
      # ```
      def self.db_fields
      end

      # Return an array of created_at fields names.
      def self.created_at_fields
      end

      # Return an array of updated_at fields names.
      def self.updated_at_fields
      end

      # Return *reference*'s class.
      #
      # ```
      # class User < Core::Model
      #   schema do
      #     reference :posts, Array(Post)
      #   end
      # end
      #
      # User.reference_class(:posts) # => Array(Post)
      # ```
      def self.reference_class(reference)
      end

      # Return *reference*'s key.
      #
      # ```
      # class Post < Core::Model
      #   schema do
      #     reference :author, User, key: :author_id
      #   end
      # end
      #
      # Post.reference_key(:author) # => :author_id
      # ```
      def self.reference_key(reference)
      end

      # Return *reference*'s foreign_key.
      #
      # ```
      # class User < Core::Model
      #   schema do
      #     reference :authored_posts, Array(Post), foreign_key: :author_id
      #   end
      # end
      #
      # User.reference_foreign_key(:authored_posts) # => :author_id
      # ```
      def self.reference_foreign_key(reference)
      end

      # Return an actual primary key value.
      #
      # ```
      # user = User.new(id: 42)
      # user.primary_key_value # => 42
      # ```
      abstract def primary_key_value

      # Return a primary key field name.
      #
      # ```
      # User.primary_key # => :id
      # ```
      def self.primary_key
      end

      # A storage for model instance changes, empty on initialize.
      # Does neither track virtual fields nor stores intial values.
      # To reset use `#changes.clear`. *Why do you need a separate method for this?*
      #
      # ```
      # user = User.new(name: "Foo")
      # user.changes.empty? # => true
      # user.name = "Bar"
      # user.changes # => {:name => "Bar"}
      # ```
      abstract def changes

      # Map the model to JSON. Ignores references.
      #
      # ```
      # user = User.new(id: 42, name: "foo", posts: [Post.new])
      # user.to_json # => {"id": 42, "name": "foo"}
      # ```
      abstract def to_json

      # Build a model from JSON. Ignores references.
      #
      # ```
      # json = "{\"id\":42,\"name\":\"foo\",\"posts\":[{\"content\":\"foobar\"}]}"
      # user = User.from_json(json)
      # user.id    # => 42
      # user.posts # => nil
      # ```
      def Schema.from_json(json)
      end

      # Build a model from `DB::ResultSet`.
      def Schema.from_rs(rs)
      end

      # A basic macro for schema definition.
      # All other macros have to be called **within** the *block*.
      # It can only be called once per model.
      #
      # ```
      # class User < Core::Model
      #   schema do
      #     primary_key :id
      #   end
      # end
      # ```
      macro schema(&block)
        CORE__FIELDS = [] of NamedTuple(
          name: Symbol,
          primary_key: Bool,
          virtual: Bool,
          type: String,
          nilable: Bool?,
          key: Symbol?,
          default: Object?,
          converter: Object?,
          emit_null: Bool?,
          created_at_field: Bool?,
          updated_at_field: Bool?,
        )

        CORE__REFERENCES = [] of NamedTuple(
          name: Symbol,
          "class": Model,
          key: Symbol?,
          foreign_key: Symbol?,
        )

        CORE__CREATED_AT_FIELDS = [] of Symbol
        CORE__UPDATED_AT_FIELDS = [] of Symbol

        {{yield}}

        define_db_fields_getters
        define_references_helpers
        define_primary_key_helpers
        define_db_mapping
        define_json_mapping
        define_initializer
        define_changes
      end

      # Set a `Model`'s table name.
      #
      # NOTE: This macro call is **mandatory** for each schema definition.
      #
      # ```
      # schema do
      #   table_name "users"
      # end
      # ```
      macro table_name(name)
        CORE__TABLE_NAME = {{name}}
        class_getter table_name = CORE__TABLE_NAME
      end

      # Define a field for **Database & JSON mapping** (see [DB::Mappable](https://github.com/crystal-lang/crystal-db/blob/master/src/db/mapping.cr) and [JSON.mapping](https://crystal-lang.org/api/latest/JSON.html#mapping-macro)).
      # A property is generated for each field.
      #
      # Possible *options*:
      # - *default* (`Object?`) - A default value for this field set on `Model` instance initialization;
      # - *primary_key* (`Bool?`) - Is this field primary key? See `#primary_key`;
      # - *virtual* (`Bool?`) - Is this field virtual? See `#virtual_field`;
      # - *key* (`Symbol?`) - Column name for this field. Defaults to *name*;
      # - *converter* (`Object?`) - An object with `#from_rs`, `#from_json` and `#to_json` methods;
      # - *created_at_field* (`Bool?`) - Whether to update this field on the first `Repository#insert`. See `#created_at_field`;
      # - *updated_at_field* (`Bool?`) - Whether to update this field on each `Repository#update`. See `#updated_at_field`.
      #
      # NOTE: `Converters::Enum` is automatically applied to all `::Enum` fields.
      # NOTE: A field is always nilable.
      #
      # ```
      # schema do
      #   field :name, String, default: "A User", key: :name_column
      # end
      # ```
      macro field(name, type _type, **options)
        property {{name.id}} : {{_type.id}} | Nil{{ " = #{options[:default]}".id if options[:default] }}

        {% CORE__CREATED_AT_FIELDS.push(name) if options[:created_at_field] %}
        {% CORE__UPDATED_AT_FIELDS.push(name) if options[:updated_at_field] %}

        {% if options[:primary_key] %}
          CORE__PRIMARY_KEY_FIELD = {{name}}
          CORE__PRIMARY_KEY_FIELD_TYPE = {{_type.id}}
        {% end %}

        {% converter = options[:converter] || ("Converters::Enum(#{_type.id})" if _type.is_a?(Path) && _type.resolve < ::Enum) || nil %}

        {% CORE__FIELDS.push({
             name:             name,
             virtual:          options[:virtual],
             type:             _type,
             primary_key:      options[:primary_key],
             nilable:          true,
             default:          options[:default],
             converter:        converter,
             created_at_field: options[:created_at_field],
             updated_at_field: options[:updated_at_field],
             key:              options[:key] || name,
           }) %}
      end

      # Define a primary key field.
      #
      # ```
      # class User < Core::Model
      #   schema do
      #     primary_key :id
      #     # Is an alias of
      #     field :id, Int32, primary_key: true
      #   end
      # end
      #
      # User.primary_key # => :id
      # user = User.new(id: 42)
      # user.primary_key_value # => 42
      # ```
      #
      # The *type* is `Int32` by default, but you pass whatever you want:
      #
      # ```
      # schema do
      #   primary_key :uuid, String
      # end
      # ```
      macro primary_key(name, type _type = Int32, converter = nil)
        field({{name}}, {{_type}}, primary_key: true, converter: {{converter}})
      end

      # Define a field which will be set to `NOW()` on `Repository#insert` only **once**.
      # There may be multiple created_at fields in a single schema.
      #
      # ```
      # schema do
      #   created_at_field :creation_time
      #   # Is an alias of
      #   field :creation_time, Time, created_at_field: true
      # end
      # ```
      #
      # NOTE: created_at field **is not set by default**. You have to define it yourself.
      macro created_at_field(name)
        field({{name}}, Time, created_at_field: true)
      end

      # Define a field which will be updated with `NOW()` each time a `Repository#update` is called.
      # There may be multiple updated_at fields in a single schema.
      #
      # ```
      # schema do
      #   updated_at_field :update_time
      #   # Is an alias of
      #   field :update_time, Time, updated_at_field: true
      # end
      # ```
      #
      # NOTE: updated_at field **is not set by default**. You have to define it yourself.
      # NOTE: This field will not be implicitly set on `Repository#insert`.
      macro updated_at_field(name)
        field({{name}}, Time, updated_at_field: true)
      end

      # Define a virtual field.
      # It will be mappable from database, but will not be mentioned in `#db_fields`.
      # It will also be mappable to/from JSON.
      #
      # ```
      # class User < Core::Model
      #   schema do
      #     virtual_field :posts_count, Int64
      #     # Is an alias of
      #     field :posts_count, Int64, virtual: true
      #   end
      # end
      #
      # user = repo.query("SELECT COUNT(posts.id) AS posts_count FROM users JOIN posts ...")
      # user.posts_count # => Actual Int64 value
      # ```
      macro virtual_field(name, type _type, **options)
        field({{name}}, {{_type}}, virtual: true, {{**options}})
      end

      # Define a reference to another `Model`.
      # It will be used in `Query#where`, `Query#having`, `Query#join` and `#db_fields` methods.
      # If a *key* is specified, it means that the current schema has this *key* as database column.
      # A *foreign_key* will be used to know which reference's key to refer to (default to reference's `.primary_key`).
      #
      # ```
      # class User
      #   primary_key :id
      #   reference :referrer, self, key: :referrer_id, foreign_key: :id
      #   reference :referrals, Array(self)
      #   reference :authored_posts, Array(Post), foreign_key: :author_id
      #   reference :edited_posts, Array(Post), foreign_key: :editor_id
      # end
      #
      # class Post
      #   reference :author, User, key: :author_id
      #   reference :editor, User, key: :editor_id
      # end
      # ```
      #
      # NOTE: A reference is always nilable.
      macro reference(name, class klass, key = nil, foreign_key = nil)
        property {{name.id}} : {{klass.id}} | Nil
        {% CORE__REFERENCES.push({
             name:        name,
             class:       klass,
             key:         key,
             foreign_key: foreign_key,
           }) %}
      end

      private macro define_db_fields_getters
        # Return a `Hash` of database field keys with their actual values.
        # Does not include virtual fields.
        #
        # ```
        # post = Post.new(author: User.new(id: 42), content: "foo")
        # post.db_fields # => {:author_id => 42, :content => "foo"}
        # ```
        def db_fields
          {
            {% for field in CORE__FIELDS.reject { |f| f[:virtual] == true } %}
              {{field[:name]}} => @{{"#{field[:name].id}".id}},
            {% end %}
            {% for reference in CORE__REFERENCES %}
              {% if reference[:key] %}
                {{reference[:key]}} => @{{"#{reference[:name].id}".id}}.try &.{{(reference[:foreign_key] || "primary_key_value").id}},
              {% end %}
            {% end %}
          } of Symbol => {{CORE__FIELDS.reject { |f| f[:virtual] == true }.map(&.[:type]).push(String).push(Nil).join(" | ").id}}
        end

        # Return an array of database field names.
        # Does not include virtual fields.
        class_getter db_fields = {
          {% for field in CORE__FIELDS.reject { |f| f[:virtual] == true } %}
            {{field[:name]}} => {{field[:type].id}},
          {% end %}
        }

        class_getter created_at_fields = {{CORE__CREATED_AT_FIELDS}}
        class_getter updated_at_fields = {{CORE__UPDATED_AT_FIELDS}}
      end

      # Define `self.reference_class`, `self.reference_key` and `self.reference_foreign_key`.
      private macro define_references_helpers
        {% for prop in %i(class key foreign_key) %}
          def self.reference_{{prop.id}}(reference)
            case reference
              {% for ref in CORE__REFERENCES %}
                when {{ref[:name]}}
                  {% if prop == :foreign_key %}
                    {{ref[prop.id]}} || {{ref[:class]}}.primary_key
                  {% else %}
                    {{ref[prop.id]}}
                  {% end %}
              {% end %}
            else
              raise ArgumentError.new("Unkown reference #{reference}!")
            end
          end
        {% end %}
      end

      private macro define_primary_key_helpers
        def primary_key_value
          @{{CORE__PRIMARY_KEY_FIELD.id}}
        end

        def self.primary_key
          {{CORE__PRIMARY_KEY_FIELD}}
        end
      end

      private macro define_db_mapping
        {% mapping = CORE__FIELDS.map do |field|
             "#{field[:name].id.stringify}: {type: #{field[:type].id}, nilable: #{field[:nilable].id}, key: #{field[:key].id.stringify}, converter: #{field[:converter].id}}"
           end %}
        {% if mapping.size > 0 %}
          DB.mapping({ {{mapping.join(", ").id}} }, false)
        {% end %}
      end

      private macro define_json_mapping
        {% mapping = CORE__FIELDS.map do |field|
             "#{field[:name].id.stringify}: {type: #{field[:type].id}, nilable: #{field[:nilable].id}, emit_null: #{field[:emit_null].id}, converter: #{field[:converter].id}, root: #{field[:root].id}, default: #{field[:default].id}}"
           end %}
        {% if mapping.size > 0 %}
          JSON.mapping({ {{mapping.join(", ").id}} })
        {% end %}
      end

      private macro define_initializer
        def initialize(
          {% for field in CORE__FIELDS %}
            @{{field[:name].id}} : {{field[:type].id}} | Nil = {{ field[:default] || nil.id }},
          {% end %}
          {% for reference in CORE__REFERENCES %}
            @{{reference[:name].id}} : {{reference[:class].id}}? = nil,
          {% end %}
        )
        end
      end

      private macro define_changes
        # A storage for a `Model`'s changes, empty on initialize. Doesn't track virtual fields. To reset use `changes.clear`.
        getter changes : Hash(Symbol, {{CORE__FIELDS.map(&.[:type]).join(" | ").id}}) = Hash(Symbol, {{CORE__FIELDS.map(&.[:type]).join(" | ").id}}).new

        {% for field in CORE__FIELDS %}
          # Track changes made to `{{field[:name].id}}`.
          def {{field[:name].id}}=(value : {{field[:type].id}})
            changes[{{field[:name]}}] = value
            @{{field[:name].id}} = value
          end
        {% end %}
      end
    end
  end
end
