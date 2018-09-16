module Core
  struct Query(T)
    private struct SetStruct
      getter clause, params

      def initialize(
        @clause : String,
        @params : Array(DB::Any | Array(DB::Any)) | Nil
      )
      end
    end

    @set : Array(SetStruct) | Nil = nil
    protected setter set

    # Add `SET` clause with params.
    #
    # Marks the query as update one, however, should be called after `#update` for readability.
    #
    # ```
    # User.update.set("name = ?", "foo").where(id: 42)
    # # UPDATE users SET name = ? WHERE id = ?
    #
    # User.set("name = ?", "foo").where(id: 42)
    # # ditto
    # ```
    def set(clause : String, *params : DB::Any | Array(DB::Any))
      ensure_set << SetStruct.new(
        clause: clause,
        params: params.to_a.map do |param|
          if param.is_a?(Array)
            param.map(&.as(DB::Any))
          else
            param.as(DB::Any | Array(DB::Any))
          end
        end,
      )

      self.update
    end

    # Add `SET` clause without params.
    #
    # Marks the query as update one, however, should be called after `#update` for readability.
    #
    # ```
    # User.update.set("updated_at = NOW()")
    # # UPDATE users SET updated_at = NOW()
    #
    # User.set("updated_at = NOW()")
    # # ditto
    # ```
    def set(clause : String)
      ensure_set << SetStruct.new(
        clause: clause,
        params: nil,
      )

      self.update
    end

    # Add `SET` clause with named arguments. Marks the query as update one.
    #
    # Arguments are validated at compilation time. To pass the validation, an argument type must be `<=` compared to the defined attribute type:
    #
    # ```
    # class User
    #   schema users do
    #     type id : Int32
    #     type active : Bool = DB::Default
    #   end
    # end
    #
    # User.update.set(active: false).where(id: 42)
    # # UPDATE users SET active = ? WHERE id = ?
    #
    # User.update.set(unknown: "foo") # Compilation time error
    # User.update.set(active: "foo")  # Compilation time error
    # ```
    #
    # Special value `DB::Default` is allowed as well:
    #
    # ```
    # User.update.set(active: DB::Default) # UPDATE users SET active = DEFAULT
    # ```
    def set(**values : **Values) : self forall Values
      {% for key, value in Values %}
        {% found = false %}

        {% for type in T::CORE_ATTRIBUTES.select(&.["key"]) %}
          {%
            value = value # Crystal bug. Remove it and it doesn't compile

            if key == type["name"]
              if type["db_default"]
                unless value <= type["type"] || value == DB::Default.class || (value.union? && value.union_types.all? { |t| t <= type["type"] || t == DB::Default.class })
                  raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#set' call. Expected: '#{type["type"]}' or 'DB::Default.class'"
                end
              else
                unless value <= type["type"]
                  raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#set' call. Expected: '#{type["type"]}'"
                end
              end

              found = true
            end
          %}
        {% end %}

        {% for type in T::CORE_REFERENCES.select { |t| t["direct"] } %}
          {%
            value = value # Crystal bug. Remove it and it doesn't compile

            if key == type["name"] # If key == type name (e.g. author)
              if type["db_default"]
                unless value <= type["type"] || value == DB::Default.class || (value.union? && value.union_types.all? { |t| t <= type["type"] || t == DB::Default.class })
                  raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#set' call. Expected: '#{type["type"]}' or 'DB::Default.class'"
                end
              else
                unless value <= type["type"]
                  raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#set' call. Expected: '#{type["type"]}'"
                end
              end

              found = true
            elsif key.stringify == type["key"] # If key == type key (e.g. author_id)
              if type["db_default"]
                unless value <= type["type"] || value == DB::Default.class || (value.union? && value.union_types.all? { |t| t <= type["type"] || t == DB::Default.class })
                  raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#set' call. Expected: '#{type["type"]}' or 'DB::Default.class'"
                end
              else
                unless value <= type["type"]
                  raise "Invalid type '#{value}' of argument '#{type["name"]}' for 'Core::Query(#{T})#set' call. Expected: '#{type["type"]}'"
                end
              end

              found = true
            end
          %}
        {% end %}

        {% raise "Class '#{T}' doesn't have an attribute with key '#{key}' defined in its Schema eligible for 'Core::Query(#{T})#set' call" unless found %}
      {% end %}

      {% begin %}
        values.each do |key, value|
          case key
            {% for type in T::CORE_ATTRIBUTES.select(&.["key"]) %}
              # set(id: 42) # "WHERE posts.id = ?", 42
              when {{type["name"].symbolize}}{{", #{type["key"].id.symbolize}".id unless type["name"].stringify == type["key"]}}
                if value.is_a?(DB::Default.class)
                  set({{type["key"]}} + " = DEFAULT")
                else
                  set({{type["key"]}} + " = ?",
                    {% if type["enumerable"] %}
                      value.unsafe_as({{type["true_type"]}}).to_db({{type["true_type"]}}),
                    {% else %}
                      value.unsafe_as({{type["true_type"]}}).to_db,
                    {% end %}
                  )
                end
            {% end %}

            # Only allow direct non-enumerable references
            {% for type in T::CORE_REFERENCES.select { |t| t["direct"] } %}
              {% pk_type = type["reference_type"].constant("PRIMARY_KEY_TYPE") %}

              # set(author: user) # "WHERE posts.author_id = ?", user.primary_key
              when {{type["name"].symbolize}}
                if value.is_a?(DB::Default.class)
                  set({{type["key"]}} + " = DEFAULT")
                else
                  set(
                    {{type["key"]}} + " = ?",
                    {% if type["enumerable"] %}
                      value.unsafe_as(Enumerable({{type["reference_type"]}})).map(&.primary_key).to_db(Enumerable({{pk_type}})),
                    {% else %}
                      value.unsafe_as({{type["reference_type"]}}).primary_key.to_db,
                    {% end %}
                  )
                end

              # set(author_id: 42) # "WHERE posts.author_id = ?", 42
              when {{type["key"].id.symbolize}}
                if value.is_a?(DB::Default.class)
                  set({{type["key"]}} + " = DEFAULT")
                else
                  set(
                    {{type["key"]}} + " = ?",
                    {% if type["enumerable"] %}
                      value.unsafe_as({{pk_type}}).to_db,
                    {% else %}
                      value.unsafe_as(Enumerable({{pk_type}})).to_db(Enumerable({{pk_type}}))
                    {% end %}
                  )
                end
            {% end %}
          else
            raise "Bug: unexpected key '#{key}'"
          end
        end
      {% end %}

      self.update
    end

    protected def ensure_set
      @set = Array(SetStruct).new if @set.nil?
      @set.not_nil!
    end

    private macro append_set(query)
      if @set.nil? || ensure_set.empty?
        raise ArgumentError.new("Cannot append empty SET values. Be sure to call at least one #set before")
      end

      {{query}} += ' ' + @set.not_nil!.map(&.clause).join(", ")

      ensure_params.concat(@set.not_nil!.map(&.params).flat_map(&.itself).compact)
    end
  end
end
