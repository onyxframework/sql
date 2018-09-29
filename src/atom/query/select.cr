module Atom
  struct Query(T)
    @select = [] of String | Char
    protected property :select

    # Add `SELECT` clause. Marks the query as select one.
    #
    # Similar to `#returning` and `#order_by`, if *value* is a Schema attribute, it's checked in compile-time:
    #
    # ```
    # User.select(:id) # Would raise in compile-time if `User` doesn't have attribute named `id`
    # # SELECT user.id FROM users
    #
    # User.select("foo")
    # # SELECT foo FROM users
    # ```
    #
    # If `#select` is not called and the query type is select, a default `SELECT table.*` is appended.
    def select(*values : T.class | T::Attribute | String | Char)
      @select.concat(values.map do |value|
        case value
        when T.class      then "#{T.table}.*"
        when T::Attribute then "#{T.table}.#{value.key}"
        else                   value
        end
      end)

      self.type = :select
      self
    end

    private macro append_select(query)
      {{query}} += " SELECT " + (@select.empty? ? "#{T.table}.*" : @select.join(", "))
    end
  end
end
