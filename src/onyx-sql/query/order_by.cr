module Onyx::SQL
  class Query(T)
    # The `ORDER BY` clause order.
    enum Order
      Desc
      Asc
    end

    # Add `ORDER BY` clause by either a model field or explicit `String` *value*.
    #
    # ```
    # q = User.all.order_by(:id, :desc)
    # q.build # => {"SELECT users.* FROM users ORDER BY id DESC"}
    #
    # q = User.all.order_by("foo(bar)")
    # q.build # => {"SELECT users.* FROM users ORDER BY foo(bar)"}
    # ```
    def order_by(value : T::Field | String, order : Order? = nil)
      if value.is_a?(T::Field)
        {% begin %}
          case value
          {% for ivar in T.instance_vars.reject { |iv| iv.annotation(Reference) } %}
            when .{{ivar.name}}?
              ensure_order_by.add(OrderBy.new(
                "#{@alias || {{T.annotation(Model::Options)[:table].id.stringify}}}.#{T.db_column({{ivar.name.symbolize}})}",
                order
              ))
          {% end %}
          else
            raise "BUG: #{value} didn't match any of #{T} instance variables"
          end
        {% end %}
      else
        ensure_order_by.add(OrderBy.new(value, order))
      end

      self
    end

    private struct OrderBy
      getter column, order

      def initialize(@column : String, @order : Order? = nil)
      end
    end

    @order_by : ::Set(OrderBy)? = nil

    protected def get_order_by
      @order_by
    end

    protected def ensure_order_by
      @order_by ||= ::Set(OrderBy).new
    end

    protected def append_order_by(sql, *args)
      return if @order_by.nil? || ensure_order_by.empty?

      sql << " ORDER BY "

      first = true
      ensure_order_by.each do |order_by|
        sql << ", " unless first; first = false
        sql << order_by.column

        if order = order_by.order
          sql << " " << order.to_s.upcase
        end
      end
    end
  end
end
