# :nodoc:
class String
  def to_db
    self.as(DB::Any | Array(DB::Any))
  end
end

{% for type in DB::TYPES.reject { |t| t.resolve == String || t.resolve == Bytes } %}
  # :nodoc:
  struct {{type}}
    def to_db
      self.as(DB::Any | Array(DB::Any))
    end
  end
{% end %}
