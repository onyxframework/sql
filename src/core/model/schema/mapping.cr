require "db/result_set"

module Core
  abstract class Model
    module Schema
      private class ColumnIndexer
        property value = 0
      end

      private macro define_db_mapping
        macro finished
          include ::DB::Mappable

          def self.from_rs(rs : ::DB::ResultSet)
            objects = Array(self).new

            rs.each do |rs|
              objects << self.new(rs)
            end

            return objects
          ensure
            rs.close
          end

          def initialize(rs : ::DB::ResultSet, reference = false, column_indexer : ColumnIndexer = ColumnIndexer.new)
            {% skip_file() if INTERNAL__CORE_FIELDS.empty? %}

            %temp_fields = Hash(Symbol, {{INTERNAL__CORE_FIELDS.map(&.[:type]).join(" | ").id}}).new

            \{% if !INTERNAL__CORE_REFERENCES.empty? %}
              %temp_references = Hash(Symbol, \{{INTERNAL__CORE_REFERENCES.map(&.[:type]).join(" | ").id}}).new
            \{% end %}

            while column_indexer.value < rs.column_count
              column_name = rs.column_name(column_indexer.value)

              case
                \{% for field in INTERNAL__CORE_FIELDS %}
                  # Once a field matched by key with a column, it's value will not be overriden.
                  #
                  # For example, when querying Post joining User, both have "id" column; the first occurence will go to `%temp_fields`, the second one will be skipped.
                  when column_name == \{{field[:key].id.stringify}} && !%temp_fields.has_key?(\{{field[:name]}})
                    \{% if field[:converter] %}
                      %temp_fields[\{{field[:name]}}] = \{{field[:converter]}}.from_rs(rs)
                    \{% else %}
                      %temp_fields[\{{field[:name]}}] = rs.read(\{{field[:type]}})
                    \{% end %}

                    column_indexer.value += 1
                \{% end %}
              else
                # Do not allow deep references
                if reference
                  %temp_fields.size > 0 ? break : return nil
                end

                \{% for reference in INTERNAL__CORE_REFERENCES.select{ |r| !r[:array] } %}
                  if !%temp_references.has_key?(\{{reference[:name]}}) && column_name == "_" + \{{reference[:name].id.stringify}}
                    rs.read
                    column_indexer.value += 1

                    %temp = \{{reference[:type].id}}.new(rs, \{{reference[:name]}}, column_indexer)
                    %temp_references[\{{reference[:name]}}] = %temp
                  end
                \{% end %}

                # Column is not mappable neither for self nor for any reference, skip further columns then
                break
              end
            end

            %temp_fields.each do |name, value|
              case name
                \{% for field in INTERNAL__CORE_FIELDS %}
                  when \{{field[:name]}}
                    @\{{field[:name].id}} = value.as(\{{field[:type].id}}) || \{{field[:default] || nil.id}}
                \{% end %}
              else
                raise "Unknown field #{name} in %temp_fields"
              end
            end

            \{% if !INTERNAL__CORE_REFERENCES.empty? %}
              %temp_references.each do |name, value|
                case name
                  \{% for reference in INTERNAL__CORE_REFERENCES %}
                    when \{{reference[:name]}}
                      \{% if reference[:array] %}
                        @\{{reference[:name].id}} = [value.as(\{{reference[:type].id}})]
                      \{% else %}
                        @\{{reference[:name].id}} = value.as(\{{reference[:type].id}} | Nil)
                      \{% end %}

                      \{% if reference[:key] %}
                        @\{{reference[:key].id}} ||= \{{reference[:name].id}}.try &.\{{reference[:foreign_key].id}}
                      \{% end %}
                  \{% end %}
                else
                  raise "Unknown reference #{name} in %temp_references"
                end
              end
            \{% end %}
          end
        end
      end
    end
  end
end
