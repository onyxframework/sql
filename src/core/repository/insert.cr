class Core::Repository
  module Insert
    private SQL_INSERT = <<-SQL
    INSERT INTO %{table_name} (%{keys}) VALUES %{values}
    SQL

    private SQL_LAST_INSERTED_PK = <<-SQL
    SELECT currval(pg_get_serial_sequence('%{table_name}', '%{primary_key}'))
    SQL

    # Insert a single *instance* into Database. Returns last inserted ID or nil if not inserted.
    #
    # TODO: Handle errors.
    # TODO: [RFC] Call `#query` and return `Schema` instance instead (see https://github.com/will/crystal-pg/issues/101).
    def insert(instance : Schema)
      insert([instance])
    end

    # Insert multiple *instances* into Database. Returns last inserted ID or nil if nothing was inserted.
    #
    # TODO: Handle errors.
    # TODO: [RFC] Call `#query` and return `Schema` instance instead (see https://github.com/will/crystal-pg/issues/101).
    def insert(instances : Array(Schema))
      raise ArgumentError.new("Empty array given") if instances.empty?

      classes = instances.map(&.class).to_set
      raise ArgumentError.new("Instances must be of single type, given: #{classes.join(", ")}") if classes.size > 1

      klass = instances[0].class

      instances_fields = instances.map(&.fields.dup.tap do |f|
        f.each do |k, _|
          f[k] = now if klass.created_at_fields.includes?(k) && f[k].nil?
          f[k] = default if f[k].nil? && klass.fields[k][:insert_nil]
          f.delete(k) if k == klass.primary_key[:name]
        end
      end)

      inserted_columns = instances_fields[0].keys.map { |f| klass.fields[f][:key] }

      query = SQL_INSERT % {
        table_name: klass.table,
        keys:       inserted_columns.join(", "),
        values:     instances_fields.map do |fields|
          "(" + fields.values.map { |f| f == default ? default : "?" }.join(", ") + ")"
        end.join(", "),
      }

      query = prepare_query(query)
      params = Core.prepare_params(instances_fields.map(&.values).flatten.reject { |v| v == default })

      query_logger.wrap(query) do
        rows_affected = db.exec(query, *params).rows_affected

        if rows_affected > 0
          last_pk_query = SQL_LAST_INSERTED_PK % {
            table_name:  klass.table,
            primary_key: klass.primary_key[:name],
          }

          db.scalar(last_pk_query)
        end
      end
    end
  end
end
