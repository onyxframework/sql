class Atom
  struct Query(T)
    # Possible orders for `ORDER BY` clauses.
    enum Order
      Asc
      Desc

      def to_s
        super.upcase
      end
    end

    private struct OrderBy
      getter column, order

      def initialize(
        @column : String,
        @order : Order | Nil
      )
      end
    end

    @order_by : Array(OrderBy) | Nil = nil
    protected property order_by

    # Add `ORDER BY` clause. Similar to `#select` and `#returning`, if *value* is a Schema attribute, it's checked in compile-time:
    #
    # ```
    # User.order_by(:uuid, :desc) # Would raise if `User` doesn't have attribute named `uuid`
    # # ORDER BY uuid DESC
    #
    # User.order_by("foo") # Will not checked at compile-time
    # # ORDER BY foo ASC
    # ```
    def order_by(value : T::Attribute | String, order : Order | Nil = Order::Asc)
      @order_by = Array(OrderBy).new if @order_by.nil?
      @order_by.not_nil! << OrderBy.new(
        column: value.is_a?(String) ? value : ("#{T.table}.#{value.key}"),
        order: order,
      )

      self
    end

    private macro append_order_by(query)
      unless @order_by.nil?
        {{query}} += " ORDER BY " + @order_by.not_nil!.join(", ") do |order_by|
          o = order_by.column
          o += (" #{order_by.order}") if order_by.order
          o
        end
      end
    end
  end
end
