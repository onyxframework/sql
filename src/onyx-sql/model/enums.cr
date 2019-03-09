module Onyx::SQL::Model
  macro included
    macro finished
      {% verbatim do %}
        {%
          getters = @type.methods.select do |_def|
            _def.body.is_a?(InstanceVar)
          end

          fields = getters.select do |g|
            if g.return_type.is_a?(Union)
              type = g.return_type.types.find { |t| !t.is_a?(Nil) }

              if type.resolve < Enumerable
                !(type.type_vars.first.resolve < Onyx::SQL::Model)
              else
                !(type.resolve < Onyx::SQL::Model)
              end
            end
          end

          references = getters.select do |g|
            if g.return_type.is_a?(Union)
              type = g.return_type.types.find { |t| !t.is_a?(Nil) }

              if type.resolve < Enumerable
                type.type_vars.first.resolve < Onyx::SQL::Model
              else
                type.resolve < Onyx::SQL::Model
              end
            end
          end
        %}

        {% if fields.size > 0 %}
          enum Field
            {% for field in fields %}
              {{field.body.name[1..-1].camelcase}}
            {% end %}
          end
        {% else %}
          enum Field
            Nop
          end
        {% end %}

        {% if references.size > 0 %}
          enum Reference
            {% for reference in references %}
              {{reference.body.name[1..-1].camelcase}}
            {% end %}
          end
        {% else %}
          enum Reference
            Nop
          end
        {% end %}
      {% end %}
    end
  end
end
