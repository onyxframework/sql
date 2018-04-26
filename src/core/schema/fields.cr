module Core
  module Schema
    # Define a field for **Database mapping** (see [DB::Mappable](https://github.com/crystal-lang/crystal-db/blob/master/src/db/mapping.cr)).
    #
    # A getter and setter are generated for each field.
    #
    # Possible *options*:
    # - *default* (`Proc?`) - Proc called for the field on `Model` instance initialization if it's `nil`;
    # - *nilable* (`Bool?`) - Is this field nilable? Has the same effect as providing a nilable *type*. If nilable, will generate `getter!`, otherwise `getter`;
    # - *insert_nil* (`Bool?`) - Whether to mark this field as nil on insert. As a result, when an instance is initialized explicitly (e.g. `User.new`), this field **will not** be checked against `nil`. However, if an instance is initialized implicitly (e.g. `from_rs` or `User.new(explicitly_initialized: false)`), then this field **will** be checked against `nil`. This is useful for fields which have `DEFAULT` values in database schema.
    # - *validate* (`NamedTuple`) - Which inline validations to run on this field (see `Validation`).
    # - *primary_key* (`Bool?`) - Is this field primary key? See `#primary_key`;
    # - *key* (`Symbol?`) - Column name for this field. Defaults to *name*;
    # - *converter* (`Object?`) - An object extending `Converter`;
    # - *created_at_field* (`Bool?`) - Whether to update this field on the first `Repository#insert`. See `#created_at_field`;
    # - *updated_at_field* (`Bool?`) - Whether to update this field on each `Repository#update`. See `#updated_at_field`.
    #
    # ```
    # schema do
    #   field :active, Bool, insert_nil: true
    #   field :name, String, default: "A User", key: :name_column
    #   field :age, Int32?, validate: {min: 18}
    # end
    # ```
    macro field(name, type _type, **options)
      {%
        nilable = options[:nilable].id == "nil".id ? "#{_type}".includes?("::Nil") || "#{_type}".ends_with?("?") : options[:nilable]
      %}

      @{{name.id}} : {{_type.id}} | Nil
      setter {{name.id}}
      getter{{"!".id unless nilable}} {{name.id}}

      {% INTERNAL__CORE_CREATED_AT_FIELDS.push(name) if options[:created_at_field] %}
      {% INTERNAL__CORE_UPDATED_AT_FIELDS.push(name) if options[:updated_at_field] %}

      {% if options[:primary_key] %}
        PRIMARY_KEY = {
          name: {{name}},
          type: {{_type.id}},
        }

        def self.primary_key
          PRIMARY_KEY
        end

        def primary_key
          @{{name.id}}.not_nil!
        end

        def ==(other : self)
          self.primary_key == other.primary_key
        end
      {% end %}

      {%
        converter = if options[:converter]
                      if options[:converter].is_a?(Generic)
                        (options[:converter].name.resolve.stringify.gsub(/\(\w+\)/, "(" + options[:converter].type_vars.first.resolve.stringify + ")")).id
                      else
                        options[:converter]
                      end
                    else
                      nil
                    end
      %}

      {% INTERNAL__CORE_FIELDS.push({
           name: name,
           type: (if _type.is_a?(Generic)
             _type
           else
             _type.resolve
           end),
           nilable:    nilable,
           insert_nil: !!options[:insert_nil],
           default:    options[:default],
           converter:  converter,
           key:        options[:key] || name,
           options:    options.empty? ? nil : options,
         }) %}
      end

    # Define a primary key field.
    #
    # ```
    # class User
    #   include Core::Schema
    #
    #   schema do
    #     primary_key :id
    #     # Is an alias of
    #     field :id, Core::PrimaryKey?, primary_key: true
    #   end
    # end
    #
    # User.primary_key # => :id
    # user = User.new(id: 42)
    # user.primary_key_value # => 42
    # ```
    #
    # The *type* is `Core::PrimaryKey?` by default, but you pass whatever you want:
    #
    # ```
    # schema do
    #   primary_key :uuid, String, default: SecureRandom.uuid
    # end
    # ```
    macro primary_key(name, type _type = Core::PrimaryKey?, **options)
      field({{name}}, {{_type}}, primary_key: true, {{**options}})
    end

    # Define a field which will be set to `NOW()` on `Repository#insert` only **once**.
    # There may be multiple created_at fields in a single schema.
    # A created_at field is non-nilable by default.
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
    macro created_at_field(name, **options)
      field({{name}}, Time, created_at_field: true, {{**options}})
    end

    # Define a field which will be updated with `NOW()` each time a `Repository#update` is called.
    # There may be multiple updated_at fields in a single schema.
    # An updated_at field is nilable by default.
    #
    # ```
    # schema do
    #   updated_at_field :update_time
    #   # Is an alias of
    #   field :update_time, Time?, updated_at_field: true
    # end
    # ```
    #
    # NOTE: updated_at field **is not set by default**. You have to define it yourself.
    # NOTE: This field will not be implicitly set on `Repository#insert`.
    macro updated_at_field(name, **options)
      field({{name}}, Time?, updated_at_field: true, {{**options}})
    end
  end
end
