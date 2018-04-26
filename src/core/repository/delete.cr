class Core::Repository
  module Delete
    # Issue a deletion query. Basically the same as `#exec` just calling `query.delete` before.
    #
    # ```
    # repo.delete(User.where(id: 1))
    # # Equals to
    # repo.exec(User.delete.where(id: 1))
    # ```
    def delete(query : Core::Query::Instance(T)) forall T
      query.delete
      exec(query.to_s, query.params)
    end

    private SQL_DELETE = <<-SQL
    DELETE FROM %{table_name} WHERE %{primary_key} IN (%{primary_key_values})
    SQL

    # Delete a single *instance* from Database.
    # Returns affected rows count (doesn't work for PostgreSQL driver yet: https://github.com/will/crystal-pg/issues/112).
    #
    # TODO: Handle errors.
    def delete(instance : Schema)
      delete([instance])
    end

    # Delete multiple *instances* from Database.
    # Returns affected rows count (doesn't work for PostgreSQL driver yet: https://github.com/will/crystal-pg/issues/112).
    #
    # TODO: Handle errors.
    def delete(instances : Array(Schema))
      raise ArgumentError.new("Empty array given") if instances.empty?

      classes = instances.map(&.class).to_set
      raise ArgumentError.new("Instances must be of single type, given: #{classes.join(", ")}") if classes.size > 1

      klass = instances[0].class

      query = SQL_DELETE % {
        table_name:         klass.table,
        primary_key:        klass.primary_key[:name],
        primary_key_values: instances.map { '?' }.join(", "),
      }

      query = prepare_query(query)
      params = Core.prepare_params(instances.map(&.primary_key))

      query_logger.wrap(query) do
        db.exec(query, *params).rows_affected
      end
    end
  end
end
