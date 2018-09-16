module Core::Schema
  # Would define an `initialize` method for this schema.
  #
  # Each schema has an `explicitly_initialized : Bool` property, which is set to true when this particular initializer is called.
  #
  # It would accept named arguments only (e.g. `User.new(42)` is invalid, but `User.new(id: 42)` is).
  private macro define_initializer
    property explicitly_initialized : Bool

    def initialize(*,
      {% for type in (CORE_ATTRIBUTES + CORE_REFERENCES).select { |t| !t["db_nilable"] && !t["db_default"] && !t["default_instance_value"] }.reject(&.["foreign"]) %}
        {{type["name"]}} : {{type["type"]}},
      {% end %}

      {% for type in (CORE_ATTRIBUTES + CORE_REFERENCES).select { |t| !t["db_nilable"] && !t["db_default"] && !t["default_instance_value"] }.select(&.["foreign"]) %}
        {{type["name"]}} : {{type["type"]}} | Nil = nil,
      {% end %}

      {% for type in (CORE_ATTRIBUTES + CORE_REFERENCES).reject { |t| !t["db_nilable"] && !t["db_default"] && !t["default_instance_value"] } %}
        {{type["name"]}} : {{type["type"]}}{{" | DB::Default.class".id if type["db_default"]}} = {{type["default_instance_value"]}},
      {% end %}
    )
      @explicitly_initialized = true

      {% for type in (CORE_ATTRIBUTES + CORE_REFERENCES) %}
        @{{type["name"]}} = {{type["name"]}}
      {% end %}
    end
  end
end
