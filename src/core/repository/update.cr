class Core::Repository
  module Update
    private SQL_UPDATE = <<-SQL
    UPDATE %{table_name} SET %{set_fields} WHERE %{primary_key} = ? RETURNING %{returning}
    SQL

    # Update *instance*.
    # Only fields appearing in `Schema#changes` are affected.
    # Returns affected rows count (doesn't work for PostgreSQL driver yet: [https://github.comwill/crystal-pg/issues/112](https://github.com/will/crystal-pg/issues/112)).
    #
    # NOTE: Does not check if `Schema::Validation#valid?`.
    #
    # TODO: Handle errors.
    # TODO: Multiple updates.
    # TODO: [RFC] Call `#query` and return `Schema` instance instead (see https://github.com/will/crystal-pg/issues/101).
    def update(instance : Schema)
      fields = instance.fields.select do |k, _|
        instance.changes.keys.includes?(k)
      end.tap do |f|
        f.each do |k, _|
          f[k] = now if instance.class.updated_at_fields.includes?(k)
        end
      end

      return unless fields.any?

      query = SQL_UPDATE % {
        table_name:  instance.class.table,
        set_fields:  fields.keys.map { |k| k.to_s + " = ?" }.join(", "),
        primary_key: instance.class.primary_key[:name], # TODO: Handle empty primary key
        returning:   instance.class.primary_key[:name],
      }

      query = prepare_query(query)
      params = Core.prepare_params(fields.values.push(instance.primary_key))

      query_logger.wrap(query) do
        db.exec(query, *params).rows_affected
      end
    end
  end
end
