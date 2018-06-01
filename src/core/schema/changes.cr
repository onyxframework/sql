module Core
  module Schema
    private macro define_changes
      macro finished
        \{% skip_file unless INTERNAL__CORE_FIELDS.size > 0 %}

        # A storage for changes, empty on initialize. To reset use `changes.clear`.
        @changes = Hash(Symbol, \{{INTERNAL__CORE_FIELDS.map(&.[:type]).join(" | ").id}}).new
        getter changes

        # Track changes made to fields
        \{% for field in INTERNAL__CORE_FIELDS %}
          # :nodoc:
          def \{{field[:name].id}}=(value : \{{field[:type].id}})
            changes[\{{field[:name]}}] = value unless @\{{field[:name].id}} == value
            @\{{field[:name].id}} = value
          end
        \{% end %}

        # Track changes made to references, updating fields accordingly
        \{% for reference in INTERNAL__CORE_REFERENCES.select { |r| r[:key] } %}
          # :nodoc:
          def \{{reference[:name].id}}=(value : \{{reference[:class].id}} | Nil)
            self.\{{reference[:key].id}} = value.try &.\{{reference[:foreign_key].id}}
            @\{{reference[:name].id}} = value
          end
        \{% end %}
      end
    end
  end
end
