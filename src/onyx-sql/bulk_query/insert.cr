module Onyx::SQL
  class BulkQuery(T)
    # Create a bulk insertion query. `Enumerable` has this method too.
    #
    # The resulting query would have only those columns to insert which have
    # a non-nil value in **at least one** instance.
    #
    # NOTE: Similar to `Model#insert`, this method would **raise** `NilAssertionError`
    # if any of `not_null` model variables is actually `nil`.
    #
    # NOTE: SQLite3 does not support `DEFAULT` keyword as an insertion value. A query
    # would raise `near "DEFAULT": syntax error (SQLite3::Exception)` if any of
    # the instances has a model variable with `default: true` and actual `nil` value.
    # However, if **all** instances has this variable `nil`, the column is not inserted
    # at all, therefore no error is raised.
    #
    # ```
    # BulkQuery.insert(users) == users.insert
    # ```
    #
    # ```
    # user1 = User.new(name: "Jake", settings: nil)
    # user2 = User.new(name: "John", settings: "foo")
    #
    # # Assuming that user has "settings" with DB `default: true`,
    # # this query would raise if using SQLite3 as database
    # repo.exec([user1, user2].insert)
    #
    # # To avoid that, split the insertion queries
    # repo.exec(user1.insert)
    # repo.exec(user2.insert)
    # ```
    def self.insert(instances : Enumerable(T))
      new(:insert, instances)
    end

    protected def append_insert(sql, params, params_index)
      raise "No instances to insert" if @instances.empty?

      {% begin %}
        {% columns = T.instance_vars.reject { |iv| (a = iv.annotation(Reference)) && a[:foreign_key] }.map { |iv| ((a = iv.annotation(Field) || iv.annotation(Reference)) && (k = a[:key]) && k.id.stringify) || iv.name.stringify } %}

        columns = { {{columns.map(&.stringify).join(", ").id}} }
        significant_columns = Set(String).new

        values = @instances.map do |instance|
          sary = uninitialized Union(DB::Any | Symbol | Nil)[{{columns.size}}]

          {% for ivar, index in T.instance_vars.reject { |iv| (a = iv.annotation(Reference)) && a[:foreign_key] } %}
            if !instance.{{ivar.name}}.nil?
              sary[{{index}}] = T.db_values({{ivar.name}}: instance.{{ivar.name}}!)[0]
              significant_columns.add({{columns[index]}})
            else
              {% if ann = ivar.annotation(Field) || ivar.annotation(Reference) %}
                {% if ann[:default] %}
                  sary[{{index}}] = :default
                {% elsif ann[:not_null] %}
                  raise NilAssertionError.new("{{T}}@{{ivar.name}} must not be nil on insert")
                {% else %}
                  sary[{{index}}] = nil
                {% end %}
              {% else %}
                sary[{{index}}] = nil
              {% end %}
            end
          {% end %}

          sary
        end

        sql << "INSERT INTO {{T.annotation(SQL::Model::Options)[:table].id}} ("
        sql << significant_columns.join(", ") << ") VALUES "
        sql << values.join(", ") do |v|
          '(' + v.map_with_index do |value, index|
            if significant_columns.includes?(columns[index])
              case value
              when Symbol then "DEFAULT"
              when nil    then "NULL"
              else
                if params
                  params << value
                end

                params_index ? "$#{params_index.value += 1}" : '?'
              end
            end
          end.reject(&.nil?).join(", ") + ')'
        end
      {% end %}
    end
  end
end
