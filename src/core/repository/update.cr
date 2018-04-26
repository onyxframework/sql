class Core::Repository
  module Update
    # Issue an update query. Basically the same as `#exec` just calling `query.update` before.
    #
    # ```
    # repo.update(User.set(active: true).where(id: 1))
    # # Equals to
    # repo.exec(User.update.set(active: true).where(id: 1))
    # ```
    def update(query : Core::Query::Instance) forall T
      query.update
      exec(query.to_s, query.params)
    end

    private SQL_UPDATE = <<-SQL
    UPDATE %{table_name} SET %{set_fields} WHERE %{primary_key} = ? RETURNING %{returning}
    SQL

    # Update single *instance*.
    # Only fields appearing in `Schema#changes` are affected.
    # Returns affected rows count (doesn't work for PostgreSQL driver yet: [https://github.comwill/crystal-pg/issues/112](https://github.com/will/crystal-pg/issues/112)).
    #
    # NOTE: Does not check if `Schema::Validation#valid?`.
    # NOTE: To update multiple instances, exec custom query (this is because instances may have different changes).
    #
    # TODO: Handle errors.
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
        set_fields:  fields.keys.map { |f| instance.class.fields[f][:key] + " = ?" }.join(", "),
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
