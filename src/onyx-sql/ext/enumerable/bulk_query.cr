module Enumerable(T)
  def insert
    Onyx::SQL::BulkQuery(T).insert(self)
  end

  def delete
    Onyx::SQL::BulkQuery(T).delete(self)
  end
end
