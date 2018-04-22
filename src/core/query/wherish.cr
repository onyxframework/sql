struct Core::Query(Schema)
  macro field_to_db(field, value)
    {% if field[:converter] %}
      if {{value}}.is_a?({{field[:type]}})
        {{field[:converter].id}}.to_db({{value}}).as(::DB::Any)
      else
        raise ArgumentError.new("Invalid value #{{{value}}.class} passed to {{field[:converter].id}}")
      end
    {% else %}
      if {{value}}.is_a?(::DB::Any)
        {{value}}.as(::DB::Any)
      else
        raise ArgumentError.new("Invalid value class #{{{value}}.class} for field {{field[:name]}}")
      end
    {% end %}
  end
end
