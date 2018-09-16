module Core
  struct Query(T)
    private struct Insert
      getter name, value

      def initialize(
        @name : String,
        @value : DB::Any | Array(DB::Any)
      )
      end
    end

    @insert : Array(Insert) | Nil = nil
    protected setter insert

    protected def ensure_insert
      @insert = Array(Insert).new if @insert.nil?
      @insert.not_nil!
    end

    # Add `INSERT` clause. Marks the query as insert one.
    #
    # Arguments are validated at compilation time. To pass the validation, an argument type must be `<=` compared to the defined attribute type:
    #
    # ```
    # class User
    #   schema users do
    #     type id : Int32 = DB::Default
    #     type active : Bool
    #   end
    # end
    #
    # User.insert(id: 42, active: true)  # INSERT INTO users (id, active) VALUES (?, ?)
    # User.insert(unknown: "foo")        # Compilation time error
    # User.insert(id: 42, active: "foo") # Compilation time error
    # ```
    #
    # Special value `DB::Default` is allowed too, however, it's to be skipped in the final INSERT clause:
    #
    # ```
    # User.insert(id: DB::Default, active: false) # INSERT INTO users (active) VALUES (?)
    # ```
    #
    # This method expects **all** non-nilable and non-default values to be set:
    #
    # ```
    # User.insert(id: 42) # Compilation time error because `active` is not set
    # ```
    #
    # NOTE: If all values to insert are default, please use `INSERT INTO table DEFAULT VALUES` SQL instead.
    #
    # TODO: Allow insert all defaults (change from skipping to `(key) VALUES (DEFAULT)`).
    def insert(**values : **Values) : self forall Values
      {% begin %}
        {%
          required_attributes = T::CORE_ATTRIBUTES.select do |a|
            !a["db_nilable"] && !a["db_default"]
          end.map(&.["name"]).reduce({} of Object => Bool) do |h, e|
            h[e] = false; h
          end
        %}

        {% for key, value in Values %}
          {% found = false %}

          {% for type in T::CORE_ATTRIBUTES.select(&.["key"]) %}
            {%
              value = value # Crystal bug. Remove it and it doesn't compile

              if key == type["name"]
                if type["db_default"]
                  unless value <= type["type"] || value == DB::Default.class || (value.union? && value.union_types.all? { |t| [type["type"], DB::Default.class].includes?(t) })
                    raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#insert' call. Expected: '#{type["type"]}' or 'DB::Default.class'"
                  end
                else
                  unless value <= type["type"]
                    raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#insert' call. Expected: '#{type["type"]}'"
                  end
                end

                found = true
                required_attributes[key] = true
              end
            %}
          {% end %}

          {% for type in T::CORE_REFERENCES.select { |t| t["direct"] } %}
            {%
              value = value # Crystal bug. Remove it and it doesn't compile

              if key == type["name"] # If key == type name (e.g. author)
                if type["db_default"]
                  unless value <= type["type"] || value == DB::Default.class || (value.union? && value.union_types.all? { |t| [type["type"], DB::Default.class].includes?(t) })
                    raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#insert' call. Expected: '#{type["type"]}' or 'DB::Default.class'"
                  end
                else
                  unless value <= type["type"]
                    raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#insert' call. Expected: '#{type["type"]}'"
                  end
                end

                found = true
                required_attributes[key] = true
              elsif key.stringify == type["key"] # If key == type key (e.g. author_id)
                if type["db_default"]
                  unless value <= type["type"] || value == DB::Default.class || (value.union? && value.union_types.all? { |t| [type["type"], DB::Default.class].includes?(t) })
                    raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#insert' call. Expected: '#{type["type"]}' or 'DB::Default.class'"
                  end
                else
                  unless value <= type["type"].constant("PRIMARY_KEY_TYPE")
                    raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#insert' call. Expected: '#{type["type"]}'"
                  end
                end

                found = true
                required_attributes[key] = true
              end
            %}
          {% end %}

          {% raise "Class '#{T}' doesn't have an attribute with name or key '#{key}' defined in its Schema eligible for 'Core::Query(#{T})#insert' call" unless found %}
        {% end %}

        {%
          unsatisfied_attributes = {} of Object => Bool
          required_attributes.map { |k, v| unsatisfied_attributes[k] = v unless v; nil }

          if unsatisfied_attributes.size > 0
            raise "Class '#{T}' requires " + unsatisfied_attributes.keys.map { |a| "'#{a}'" }.join(", ") + " attribute(s) to be set on 'Core::Query(#{T})#insert' call"
          end
        %}

        values.each_with_index do |key, value, index|
          if value.nil? || value.is_a?(DB::Default.class)
            next # Skip if inserting DEFAULT or NULL
          end

          case key
            {% for type in T::CORE_ATTRIBUTES.select(&.["key"]) %}
              # insert(id: 42) # "WHERE posts.id = ?", 42
              when {{type["name"].symbolize}}{{", #{type["key"].id.symbolize}".id unless type["name"].stringify == type["key"]}}
                ensure_insert << Insert.new(
                  name: {{type["key"]}},
                  value: {% if type["enumerable"] %}
                    value.unsafe_as({{type["true_type"]}}).to_db({{type["true_type"]}})
                  {% else %}
                    value.unsafe_as({{type["true_type"]}}).to_db
                  {% end %}
                )
            {% end %}

            {% for type in T::CORE_REFERENCES.select { |t| t["direct"] } %}
              {% pk_type = type["reference_type"].constant("PRIMARY_KEY_TYPE") %}

              # insert(author: user) # "WHERE posts.author_id = ?", user.primary_key
              when {{type["name"].symbolize}}
                ensure_insert << Insert.new(
                  name: {{type["key"]}},
                  value: {% if type["enumerable"] %}
                    value.unsafe_as(Enumerable({{type["reference_type"]}})).map(&.primary_key).to_db(Enumerable({{pk_type}})),
                  {% else %}
                    value.unsafe_as({{type["reference_type"]}}).primary_key.to_db,
                  {% end %}
                )

              # insert(author_id: 42) # "WHERE posts.author_id = ?", 42
              when {{type["key"].id.symbolize}}
                ensure_insert << Insert.new(
                  name: {{type["key"]}},
                  value: {% if type["enumerable"] %}
                    value.unsafe_as({{pk_type}}).to_db,
                  {% else %}
                    value.unsafe_as(Enumerable({{pk_type}})).to_db(Enumerable({{pk_type}}))
                  {% end %}
                )
            {% end %}
          else
            raise "Bug: unexpected key '#{key}'"
          end
        end
      {% end %}

      self.type = :insert
      self
    end

    private macro append_insert(query)
      if @insert.nil? || @insert.not_nil!.empty?
        raise ArgumentError.new("Cannot append empty INSERT values. Ensure to call #insert before. Or if you want to insert all columns default, use 'INSERT INTO table DEFAULT VALUES' SQL query instead")
      end

      {{query}} += " (#{@insert.not_nil!.map(&.name).join(", ")}) VALUES (#{@insert.not_nil!.join(", ") { '?' }})"
      ensure_params.concat(@insert.not_nil!.map(&.value))
    end
  end
end
