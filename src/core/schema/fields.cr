module Core
  module Schema
    # Define a schema field, generating properties for each field.
    #
    # Possible *options*:
    # - *default* (`Proc?`) - Proc called for the field on instance initialization if it's `nil`;
    # - *nilable* (`Bool?`) - Whether is this field nilable. Has the same effect as providing a nilable *type*. If nilable, will generate `getter!`, otherwise just `getter` (see https://crystal-lang.org/api/0.24.2/Object.html#getter%21%28%2Anames%29-macro);
    # - *db_default* (`Bool?`) - Whether is this field has `DEFAULT` value handled by database. As a result, when an instance is initialized explicitly (e.g. `User.new`), this field **will not** be checked against `nil`. However, if an instance is initialized implicitly (e.g. `from_rs` or `User.new(explicitly_initialized: false)`), then this field **will** be checked against `nil`, failing validation if not nilable.
    # - *primary_key* (`Bool?`) - Is this field a primary key? See `#primary_key`;
    # - *key* (`Symbol?`) - Column name for this field. Defaults to *name*;
    # - *converter* (`Object?`) - An object extending `Core::Converter`;
    #
    # ```
    # schema do
    #   field :active, Bool, db_default: true
    #   field :name, String, default: "A User", key: :name_column
    #   field :age, Int32?
    # end
    # ```
    macro field(name, type _type, **options)
      {%
        nilable = options[:nilable].id == "nil".id ? "#{_type}".includes?("::Nil") || "#{_type}".ends_with?("?") : options[:nilable]
      %}

      @{{name.id}} : {{_type.id}} | Nil
      setter {{name.id}}
      getter{{"!".id unless nilable}} {{name.id}}

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
                        (options[:converter].name.resolve.stringify.gsub(/\([\w, ]+\)/, "(" + options[:converter].type_vars.map { |v| v.resolve.stringify }.join(", ") + ")")).id
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
             if ("#{_type.name.resolve}" == "Array(T)")
               _type.name.resolve.stringify.gsub(/\([\w, ]+\)/, "(" + _type.type_vars.map do |v|
                 v.resolve.stringify
               end.join(", ") + ")").id
             else
               _type
             end
           else
             _type.resolve
           end),
           nilable:    nilable,
           db_default: !!options[:db_default],
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
  end
end
