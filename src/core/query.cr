require "./query/*"

module Core
  # Include this module into your models:
  #
  # ```
  # class User
  #   include Core::Schema
  #   include Core::Query
  #
  #   schema :users do
  #     primary_key :id
  #     field :name, String
  #   end
  # end
  #
  # repo.query_one(User.where(id: 42))
  # ```
  #
  # Or use it separately (without module inclusion):
  #
  # ```
  # repo.query_one(Core::Query.new(User).where(id: 42))
  # # or
  # repo.query_one(Core::Query::Instance(User).new.where(id: 42))
  # ```
  #
  # In both cases will return `Query::Instance` instances.
  module Query
    macro new(klass)
      {{@type}}::Instance({{klass}}).new
    end

    macro included
      {% for method in %w(
                         group_by
                         having
                         not_having
                         or_having
                         or_not_having
                         and_having
                         and_not_having
                         join
                         inner_join
                         left_join
                         right_join
                         full_join
                         left_inner_join
                         right_inner_join
                         full_inner_join
                         left_outer_join
                         right_outer_join
                         full_outer_join
                         limit
                         offset
                         order_by
                         select
                         where
                         where_not
                         and_where
                         and_where_not
                         or_where
                         or_where_not
                         and
                         and_not
                         or
                         or_not
                       ) %}
        # Create new `Query::Instance` and call {{method}} on it
        def self.{{method.id}}(*args)
          Instance(self).new.{{method.id}}(*args)
        end

        # :nodoc:
        def self.{{method.id}}(**args)
          Instance(self).new.{{method.id}}(**args)
        end

        # :nodoc:
        def self.{{method.id}}(*args, **nargs)
          Instance(self).new.{{method.id}}(*args, **nargs)
        end
      {% end %}

      {% for method in %w(
                         all
                         one
                         last
                         first) %}
        def self.{{method.id}}
          Instance(self).new.{{method.id}}
        end
      {% end %}
    end
  end
end
