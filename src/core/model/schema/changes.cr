module Core
  abstract class Model
    module Schema
      private macro define_changes
        {% skip() unless INTERNAL__CORE_FIELDS.size > 0 %}

        # A storage for a `Model`'s changes, empty on initialize. Doesn't track virtual fields. To reset use `changes.clear`.
        @changes = Hash(Symbol, {{INTERNAL__CORE_FIELDS.map(&.[:type]).join(" | ").id}}).new
        getter changes

        {% for field in INTERNAL__CORE_FIELDS %}
          # Track changes made to `{{field[:name].id}}`.
          def {{field[:name].id}}=(value : {{field[:type].id}})
            changes[{{field[:name]}}] = value unless @{{field[:name].id}} == value
            @{{field[:name].id}} = value
          end
        {% end %}

        {% for reference in INTERNAL__CORE_REFERENCES.select(&.[:key]) %}
          # If `{{reference[:name].id}}` is changed, `{{reference[:key].id}}` is changed too.
          def {{reference[:name].id}}=(value : {{reference[:class].id}} | Nil)
            self.{{reference[:key].id}} = value.try &.{{reference[:foreign_key].id}}
            @{{reference[:name].id}} = value
          end
        {% end %}
      end
    end
  end
end
