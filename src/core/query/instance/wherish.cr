struct Core::Query::Instance(Schema)
  macro field_to_db(field, value)
    {% if field[:converter] %}
      if {{value}}.is_a?({{field[:type]}})
        {{field[:converter].id}}.to_db({{value}}).as(Param)
      else
        raise ArgumentError.new("Invalid value #{{{value}}.class} passed to {{field[:converter].id}}")
      end
    {% else %}
      if {{value}}.is_a?(Param)
        {{value}}.as(Param)
      else
        raise ArgumentError.new("Invalid value class #{{{value}}.class} for field {{field[:name]}}")
      end
    {% end %}
  end

  @last_wherish_clause = :where

  {% for joinder in %w(and or) %}
    {% for not in [true, false] %}
      # A shorthand for calling `{{joinder.id}}_where{{"_not" if not}}` or `{{joinder.id}}_{{"not_" if not}}having` depending on the last clause call.
      #
      # ```
      # query.where(foo: "bar").{{joinder.id}}{{"_not" if not}}(baz: "qux")
      # # => WHERE (foo = 'bar') {{joinder.upcase.id}}{{" NOT" if not}} (baz = 'qux')
      # query.having(foo: "bar").{{joinder.id}}{{"_not" if not}}(baz: "qux")
      # # => HAVING (foo = 'bar') {{joinder.upcase.id}}{{" NOT" if not}} (baz = 'qux')
      # ```
      def {{joinder.id}}{{"_not".id if not}}(**args)
        case @last_wherish_clause
        when :having
          {{joinder.id}}{{"_not".id if not}}_having(**args)
        else
          {{joinder.id}}_where{{"_not".id if not}}(**args)
        end
      end

      # :nodoc:
      def {{joinder.id}}{{"_not".id if not}}(*args)
        case @last_wherish_clause
        when :having
          {{joinder.id}}{{"_not".id if not}}_having(*args)
        else
          {{joinder.id}}_where{{"_not".id if not}}(*args)
        end
      end

      # :nodoc:
      def {{joinder.id}}{{"_not".id if not}}(*args, **nargs)
        case @last_wherish_clause
        when :having
          {{joinder.id}}{{"_not".id if not}}_having(*args, **nargs)
        else
          {{joinder.id}}_where{{"_not".id if not}}(*args, **nargs)
        end
      end
    {% end %}
  {% end %}
end
