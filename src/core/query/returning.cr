module Core
  struct Query(T)
    @returning : Array(String | Char) | Nil = nil

    # It's a public property because it's smart to allow repository to change `returning` based on query type (query, exec or scalar).
    property returning

    # Add `RETURNING` clause.
    #
    # Similar to `#select` and `#order_by`, if *value* is a Schema attribute, it's checked in compile-time:
    #
    # ```
    # User.insert(name: "Foo").returning(:id) # Would raise in compile-time if `User` doesn't have attribute named `id`
    # # INSERT INTO users (name) VALUES (?) RETURNING users.id
    # ```
    def returning(*values : T::Attribute | String | Char)
      @returning = Array(String | Char).new if @returning.nil?
      @returning.not_nil!.concat(values.map do |value|
        case value
        when T::Attribute then "#{T.table}.#{value.key}"
        else                   value
        end
      end)

      self
    end

    private macro append_returning(query)
      unless @returning.nil?
        {{query}} += " RETURNING " + @returning.not_nil!.join(", ")
      end
    end
  end
end
