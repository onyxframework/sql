class Core::Repository
  module Insert
    private SQL_INSERT = <<-SQL
    INSERT INTO %{table_name} (%{keys}) VALUES (%{values})
    SQL

    private SQL_LAST_INSERTED_PK = <<-SQL
    SELECT currval(pg_get_serial_sequence('%{table_name}', '%{primary_key}'))
    SQL

    # Insert *instance* into Database. Returns last inserted ID or nil if not inserted.
    #
    # NOTE: Does not check if `Model::Validation#valid?`.
    #
    # TODO: Handle errors.
    # TODO: Multiple inserts.
    # TODO: [RFC] Call `#query` and return `Model` instance instead (see https://github.com/will/crystal-pg/issues/101).
    def insert(instance : Model)
      fields = instance.fields.dup.tap do |f|
        f.each do |k, _|
          f[k] = now if instance.class.created_at_fields.includes?(k) && f[k].nil?
          f.delete(k) if k == instance.class.primary_key[:name]
        end
      end

      query = SQL_INSERT % {
        table_name: instance.class.table,
        keys:       fields.keys.join(", "),
        values:     (1..fields.size).map { "?" }.join(", "),
      }

      query = prepare_query(query)
      params = Core.prepare_params(fields.values)

      query_logger.wrap(query) do
        rows_affected = db.exec(query, *params).rows_affected

        if rows_affected > 0
          last_pk_query = SQL_LAST_INSERTED_PK % {
            table_name:  instance.class.table,
            primary_key: instance.class.primary_key[:name],
          }

          db.scalar(last_pk_query)
        end
      end
    end
  end
end
