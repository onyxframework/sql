module Onyx::SQL
  class BulkQuery(T)
    # Create a bulk deletion query. `Enumerable` has this method too.
    #
    # NOTE: Deletion relies on instances' primary key values. The query would **raise**
    # `NilAssertionError` upon building if any of the instances has its primary key `nil`.
    #
    # ```
    # BulkQuery.delete(users) == users.delete
    # ```
    def self.delete(instances : Enumerable(T))
      new(:delete, instances)
    end

    protected def append_delete(sql, *args)
      raise "No instances to delete" if @instances.empty?

      {% begin %}
        {% table = T.annotation(SQL::Model::Options)[:table] %}
        sql << "DELETE FROM {{table.id}}"
        append_where(sql, *args)
      {% end %}
    end
  end
end
