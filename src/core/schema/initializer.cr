module Core
  module Schema
    private macro define_initializer
      property explicitly_initialized : Bool

      macro finished
        def initialize(
          {% for field in INTERNAL__CORE_FIELDS %}
            @{{field[:name].id}} : {{field[:type].id}} | Nil = {{ field[:default] || nil.id }},
          {% end %}

          \{% for reference in INTERNAL__CORE_REFERENCES %}
            @\{{reference[:name].id}} : \{{reference[:class].id}} | Nil = nil,
          \{% end %}

          @explicitly_initialized = true,
        )
          \{% for reference in INTERNAL__CORE_REFERENCES.select(&.[:key]) %}
            @\{{reference[:key].id}} ||= \{{reference[:name].id}}.try &.\{{reference[:foreign_key].id}}
          \{% end %}
        end
      end
    end
  end
end
