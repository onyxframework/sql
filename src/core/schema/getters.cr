module Core
  module Schema
    private macro define_getters(table)
      macro finished
        TABLE = {{table}}

        def self.table
          TABLE.to_s
        end

        \{% if INTERNAL__CORE_FIELDS.size > 0 %}
          FIELDS = {
            \{% for field in INTERNAL__CORE_FIELDS %}
              \{{field[:name]}} => {
                type: \{{field[:type].id}},
                converter: \{{field[:converter].id}},
                key: \{{field[:key].id.stringify}},
                db_default: \{{field[:db_default]}},
              },
            \{% end %}
          }

          def self.fields
            FIELDS
          end

          # Return a `Hash` of field keys with their actual values.
          #
          # ```
          # user = User.new(id: 42)
          # post = Post.new(author_id: user.id, content: "foo")
          # post.fields # => {:author_id => 42, :content => "foo"}
          # ```
          def fields
            {
              \{% for field in INTERNAL__CORE_FIELDS %}
                \{%
                  val = if field[:converter]
                          "@#{field[:name].id}.try{ |f| #{field[:converter]}.to_db(f) }"
                        else
                          "@#{field[:name].id}"
                        end
                %}
                \{{field[:name]}} => \{{val.id}},
              \{% end %}
            } of Symbol => \{{INTERNAL__CORE_FIELDS.map(&.[:type]).join(" | ").id}}
          end
        \{% end %}

        \{% if INTERNAL__CORE_REFERENCES.size > 0 %}
          REFERENCES = {
            \{% for reference in INTERNAL__CORE_REFERENCES %}
              \{{reference[:name]}} => {
                "class": \{{reference[:class].id}},
                type: \{{reference[:type].id}},
                key: \{{reference[:key]}},
                foreign_key: \{{reference[:foreign_key]}}
              },
            \{% end %}
          }

          def self.references
            REFERENCES
          end
        \{% else %}
          def self.references
            {} of Symbol => Hash(Symbol, Nil)
          end
        \{% end %}
      end
    end
  end
end
