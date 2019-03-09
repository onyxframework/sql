require "../query"

# This module is **extended** by an object whenever it includes the `Model` module.
# It brings shortucts to a matching query initialization:
#
# ```
# class User
#   include Onyx::SQL::Model
# end
#
# User.query == Query(User).new
# ```
module Onyx::SQL::Model::ClassQueryShortcuts(T)
  # Create a new `Query(T)`.
  def query : Query
    Query(T).new
  end

  {% for method in %w(
                     delete
                     group_by
                     insert
                     limit
                     offset
                     set
                     update
                     where
                     having
                     all
                     one
                   ) %}
    # Create a new `Query(self)` and call `Query#{{method.id}}` on it.
    def {{method.id}}(*args, **nargs) : Query(T)
      query.{{method.id}}(*args, **nargs)
    end
  {% end %}

  # Create a new `Query(self)` and call `Query#order_by` on it.
  def order_by(value : T::Field | String, order : Query::Order? = nil) : Query(T)
    query.order_by(value, order)
  end

  # Create a new `Query(self)` and call `Query#returning` on it.
  def returning(values : Enumerable(T::Field | T::Reference | Char | String))
    query.returning(values)
  end

  # ditto
  def returning(*values : T::Field | T::Reference | Char | String)
    returning(values)
  end

  # ditto
  def returning(klass : T.class, *values : T::Field | T::Reference | Char | String)
    query.returning(klass, *values)
  end

  # Create a new `Query(self)` and call `Query#select` on it.
  def select(values : Enumerable(T::Field | T::Reference | Char | String))
    query.select(values)
  end

  # ditto
  def select(*values : T::Field | T::Reference | Char | String)
    self.select(values)
  end

  # ditto
  def select(klass : T.class, *values : T::Field | T::Reference | Char | String)
    query.select(klass, *values)
  end

  # Create a new `Query(self)` and call `Query#join` on it.
  def join(table : String, on : String, as _as : String? = nil, type : Onyx::SQL::Query::JoinType = :inner) : Query(T)
    query.join(table, on, _as, type)
  end

  # ditto
  def join(reference : T::Reference, on : String? = nil, as _as : String = reference.to_s.underscore, type : Onyx::SQL::Query::JoinType = :inner) : Query(T)
    query.join(reference, on, _as, type)
  end

  # ditto
  def join(reference : T::Reference, klass, *, on : String? = nil, as _as : String = reference.to_s.underscore, type : JoinType = :inner, &block)
    query.join(reference, klass, on: on, as: _as, type: type, &block)
  end
end
