class Atom
  module Model
    private macro define_query_enums
      enum Attribute
        {% for type in MODEL_ATTRIBUTES %}
          {{type["name"].capitalize}}
        {% end %}

        def key
          case value
          {% for type, i in MODEL_ATTRIBUTES %}
            when {{i}} then {{type["key"]}}
          {% end %}
          else raise "Bug: unknown value '#{value}'"
          end
        end
      end

      # Forbid direct enumerable references to join (e.g. `type tags : Array(Tag), key: "tag_ids"`)
      {% references = MODEL_REFERENCES.reject { |r| r["direct"] && r["enumerable"] } %}

      {% if references.size > 0 %}
        enum Reference
          {% for type in references %}
            {{type["name"].capitalize}}
          {% end %}

          def direct?
            case value
            {% for type, i in references %}
              when {{i}} then {{type["direct"]}}
            {% end %}
            else raise "Bug: unknown value '#{value}'"
            end
          end

          def foreign?
            case value
            {% for type, i in references %}
              when {{i}} then {{type["foreign"]}}
            {% end %}
            else raise "Bug: unknown value '#{value}'"
            end
          end

          def table
            case value
            {% for type, i in references %}
              when {{i}}
                {{type["reference_type"].constant("MODEL_TABLE")}}
            {% end %}
            else
              raise "Bug: unknown value '#{value}'"
            end
          end

          def key
            case value
            {% for type, i in references %}
              when {{i}}
                {% if type["direct"] %}
                  {{type["key"]}}
                {% else %}
                  raise "Foreign references don't have table keys"
                {% end %}
            {% end %}
            else
              raise "Bug: unknown value '#{value}'"
            end
          end

          def foreign_key
            case value
            {% for type, i in references %}
              when {{i}}
                {% if type["foreign"] %}
                  {{type["foreign_key"]}}
                {% else %}
                  raise "Direct references don't have foreign table keys"
                {% end %}
            {% end %}
            else raise "Bug: unknown value '#{value}'"
            end
          end

          def primary_key
            case value
            {% for type, i in references %}
              when {{i}} then {{type["reference_type"].constant("MODEL_PRIMARY_KEY")}}
            {% end %}
            else raise "Bug: unknown value '#{value}'"
            end
          end
        end
      {% end %}
    end
  end
end
