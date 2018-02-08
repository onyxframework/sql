class Core::Repository
  module Delete
    private SQL_DELETE = <<-SQL
    DELETE FROM %{table_name} WHERE %{primary_key} = ?
    SQL

    # Delete *instance* from Database.
    # Returns affected rows count (doesn't work for PostgreSQL driver yet: https://github.com/will/crystal-pg/issues/112).
    #
    # TODO: Handle errors.
    # TODO: Multiple deletes.
    def delete(instance : Model)
      query = SQL_DELETE % {
        table_name:  instance.class.table,
        primary_key: instance.class.primary_key[:name],
      }

      query = prepare_query(query)
      params = Core.prepare_params(instance.primary_key)

      query_logger.wrap(query) do
        db.exec(query, *params).rows_affected
      end
    end
  end
end
