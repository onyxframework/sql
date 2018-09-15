module Core::Schema
  private macro define_query_shortcuts
    def self.query
      Core::Query(self).new
    end

    {% for method in %w(group_by having insert limit offset set where) %}
      # Create new `Core::Query` and call {{method}} on it.
      def self.{{method.id}}(*args, **nargs)
        query.{{method.id}}(*args, **nargs)
      end
    {% end %}

    {% for method in %w(update delete all one first last) %}
      def self.{{method.id}}
        query.{{method.id}}
      end
    {% end %}

    def self.join(table : String, on : String, *, type _type : Core::Query::JoinType = :inner, as _as : String | Nil = nil)
      query.join(table, on, type: _type, as: _as)
    end

    def self.join(reference : Reference, *, type _type : Core::Query::JoinType = :inner, **options)
      query.join(reference, **options, type: _type)
    end

    def self.order_by(value : Attribute | String, order : Core::Query::Order | Nil = nil)
      query.order_by(value, order)
    end

    def self.returning(*values : Attribute | String | Char)
      query.returning(*values)
    end

    def self.select(*values : Attribute | String | Char)
      query.select(*values)
    end
  end
end
