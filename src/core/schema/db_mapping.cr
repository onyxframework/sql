module Core::Schema
  # :nodoc:
  module Mapping
    # It's a class because it's value needs to be changed within recursive calls.
    class ColumnIndexer
      property value = 0
    end
  end

  private macro define_db_mapping
    # Read an array of self from [`DB::ResultSet`](http://crystal-lang.github.io/crystal-db/api/latest/DB/ResultSet.html).
    def self.from_rs(rs : DB::ResultSet) : Array(self)
      instances = [] of self
      rs.each do
        instances << self.new(rs)
      end
      instances
    ensure
      rs.close
    end

    protected def initialize(soft : Bool, *,
      {% for type in (CORE_ATTRIBUTES + CORE_REFERENCES) %}
        @{{type["name"]}} : {{type["type"]}}{{" | DB::Default.class".id if type["db_default"]}} | Nil = {{type["default_instance_value"]}},
      {% end %}
    )
      @explicitly_initialized = false
    end

    protected def initialize(rs : DB::ResultSet, is_reference = false, column_indexer : Mapping::ColumnIndexer = Mapping::ColumnIndexer.new)
      @explicitly_initialized = false

      types_already_set = Hash(String, Bool).new

      while column_indexer.value < rs.column_count
        column_name = rs.column_name(column_indexer.value)

        {% begin %}
          case
            {% for type in CORE_ATTRIBUTES %}
              when column_name == {{type["key"].id.stringify}} && !types_already_set[{{type["name"].stringify}}]?

                @{{type["name"]}} = {% if type["type"] < Enum || type["type"] < Hash %}
                  rs.read({{type["type"]}})
                {% else %}
                  rs.read({{type["type"]}} | Nil)
                {% end %}

                types_already_set[{{type["name"].stringify}}] = true
                column_indexer.value += 1
            {% end %}

            # Initialize direct references with their primary keys only
            {% for type in CORE_REFERENCES.select { |r| r["direct"] } %}
              when column_name == {{type["key"].id.stringify}} && !types_already_set[{{type["name"].stringify}}]?
                # Consider incoming values as an array of references' primary key values
                # and try to initialize them as enumerable of instances with only primary keys set
                #
                # ```
                # class User
                #   pkey uuid : UUID
                # end
                #
                # class Post
                #   type users : Array(User), key: "user_uuids"
                # end
                # ```
                #
                # ```text
                # | user_uuids        |
                # | ----------------- |
                # | {abc-def,xyz-123} |
                # ```
                #
                # ```
                # post # => Post<@users=[User<@uuid="abc-def">, User<@uuid="xyz-123">]>
                # ```
                {% pk = type["reference_type"].constant("PRIMARY_KEY") %}
                {% pk_type = type["reference_type"].constant("PRIMARY_KEY_TYPE") %}

                {% if type["enumerable"] %}
                  @{{type["name"]}} = rs.read({{type["enumerable"]}}({{pk_type}}) | Nil).try &.map do |pk|
                    {{type["reference_type"]}}.new(true, {{pk}}: pk)
                  end

                # Consider incoming values as a reference primary key value
                # and try to initialize its instance with only primary key value set
                #
                # ```
                # class User
                #   pkey uuid : UUID
                #   type referrer : User, key: "referrer_uuid"
                # end
                # ```
                #
                # ```text
                # | referrer_uuid |
                # | ------------- |
                # | abc-def-...   |
                # ```
                #
                # ```
                # user # => User<@referrer=User<@uuid="abc-def-"> @name="...">
                # ```
                {% else %}
                  @{{type["name"]}} = rs.read({{pk_type}} | Nil).try { |pk| {{type["reference_type"]}}.new(true, {{pk}}: pk) }
                {% end %}

                types_already_set[{{type["name"].stringify}}] = true
                column_indexer.value += 1
            {% end %}
          else
            # Do not allow deep preloaded references (yet?)
            return if is_reference

            # Preload non-enumerable references (both direct and foreign)
            {% for type in CORE_REFERENCES.reject(&.["enumerable"]) %}
              # Check if current column is a reference marker (e.g. "_referrer")
              # Do not check for `!types_already_set` because "_referrer" takes higher precedence
              if column_name == "_" + {{type["name"].stringify}}

                # Skip marker column because it doesn't have any data
                rs.read
                column_indexer.value += 1

                # Read reference's attributes from further columns
                @{{type["name"]}} = {{type["reference_type"]}}.new(rs, true, column_indexer)
                types_already_set[{{type["name"].stringify}}] = true

                next
              end
            {% end %}

            # Unknown column in the result set
            raise DB::MappingException.new("#{{{@type}}}: cannot map column #{column_name} from a result set at index #{column_indexer.value}")
          end
        {% end %}
      end
    end
  end
end
