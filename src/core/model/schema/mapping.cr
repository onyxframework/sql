module Core
  abstract class Model
    module Schema
      private macro define_mapping
        {% mapping = INTERNAL__CORE_FIELDS.map do |field|
             _type = field[:type].is_a?(Generic) ? field[:type].type_vars.first.id : field[:type].id

             "#{field[:name].id}: {\
                type: #{_type}, \
                nilable: #{field[:nilable].id}, \
                key: #{field[:key].id.stringify}, \
                converter: #{field[:converter].id}, \
                default: #{field[:default]}\
              }"
           end %}
        {% if mapping.size > 0 %}
          # Note that it's a custom mapping (see src/db/mapping.cr)
          Core::DB.mapping({{{mapping.join(", ").id}}})
        {% end %}
      end
    end
  end
end
