require "./schema/**"

module Core
  # This module allows to define mapping from DB to a model.
  #
  # Be sure to fill it thouroughly with all databse columns, otherwise errors may occure.
  #
  # **Example:**
  #
  # Given SQL:
  #
  # ```sql
  # CREATE TABLE users (
  #   id SERIAL PRIMARY KEY,
  #   name TEXT NOT NULL,
  #   active BOOLEAN NOT NULL DEFAULT true,
  #   age INT
  # );
  #
  # CREATE TABLE posts (
  #   id SERIAL PRIMARY KEY,
  #   author_id INT NOT NULL REFERENCES users (id),
  #   content TEXT NOT NULL,
  #   created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  #   updated_at TIMESTAMPTZ
  # );
  # ```
  #
  # A proper schema for it:
  #
  # ```
  # class User
  #   include Core::Schema
  #
  #   schema users do
  #     pkey id : Int32
  #     type name : String
  #     type active : Bool = DB::Default
  #     type age : Union(Int32 | Nil)
  #     type posts : Array(Post) # Implicit reference
  #   end
  # end
  #
  # class Post
  #   include Core::Schema
  #
  #   schema posts do
  #     pkey id : Int32
  #     type author : User, key: "author_id" # Explicit reference
  #     type content : String
  #     type created_at : Time = DB::Default
  #     type updated_at : Union(Time | Nil)
  #   end
  # end
  # ```
  #
  # Would also define special enums `Attribute` and `Reference`, e.g. `Attribute::Id` and `Reference::Author`.
  #
  # `Attribute` enums have `#key` method which returns table key for this attribute.
  #
  # `Reference` enums have multiple methods:
  #
  # - `#direct?` - whether is this reference direct (e.g. `true` for `Reference::Author`)
  # - `#foreign?` - whether is this reference foreign (e.g. `true` for `Reference::Posts`)
  # - `#table` - returns table name (e.g. `"users"` for `Reference::Author`)
  # - `#key` - returns table key (e.g. `"author_id"` for `Reference::Author`)
  # - `#foreign_key` - returns foreign table key (e.g. `"author_id"` for `Reference::Posts`)
  # - `#primary_key` - returns table key for this reference's primary key (e.g. `"id"` for both refrences in this case)
  module Schema
    # Define mapping from DB to model (and vice-versa) for the *table*.
    macro schema(table, &block)
      CORE_TABLE = {{table.id.stringify}}

      def self.table
        {{table.id.stringify}}
      end

      CORE_ATTRIBUTES = [] of NamedTuple
      CORE_REFERENCES = [] of NamedTuple

      macro finished
        {{yield.id}}

        define_initializer
        define_changes
        define_query_enums
        define_query_shortcuts
        define_db_mapping
      end
    end

    # Will be defined after `.schema` call. It would accept named arguments only, e.g. `User.new(id: 42)`.
    abstract def initialize(**nargs)

    # A storage for instance changes; will be defined after `.schema` call. Would not track foreign references changes.
    abstract def changes

    # Method to map instances from `DB::ResultSet`; will be defined after `.schema` call.
    def self.from_rs : Array(self)
      {% raise NotImplementedError %}
    end

    # Would return a `Schema::Attribute` for shema's primary key; will be defined after `.schema` call.
    def self.primary_key
      {% raise NotImplementedError %}
    end

    # Would safely return instance primary key or `nil` if not set; will be defined after `.schema` call.
    abstract def primary_key?

    # Would return instance primary key or raise `ArgumentError` if not set; will be defined after `.schema` call.
    abstract def primary_key

    # Would check two instances for equality by their `primary_key` values; will be defined after `.schema` call. Would raise `ArgumentError` if any of instances had primary key value not set.
    abstract def ==(other : self)
  end
end
