require "db/result_set"

module Core::DB
  macro mapping(properties)
    include ::DB::Mappable

    {% for key, value in properties %}
      {% properties[key] = {type: value} unless value.is_a?(HashLiteral) || value.is_a?(NamedTupleLiteral) %}
    {% end %}

    {% for key, value in properties %}
      {% value[:nilable] = true if value[:type].is_a?(Generic) && value[:type].type_vars.map(&.resolve).includes?(Nil) %}

      {% if value[:type].is_a?(Call) && value[:type].name == "|" &&
              (value[:type].receiver.resolve == Nil || value[:type].args.map(&.resolve).any?(&.==(Nil))) %}
        {% value[:nilable] = true %}
      {% end %}
    {% end %}

    def self.from_rs(%rs : ::DB::ResultSet)
      %objs = Array(self).new
      %rs.each do
        %objs << self.new(%rs)
      end
      %objs
    ensure
      %rs.close
    end

    def initialize(%rs : ::DB::ResultSet)
      {% for key, value in properties %}
        %var{key.id} = nil
        %found{key.id} = false
      {% end %}

      %rs.each_column do |col_name|
        case col_name
          {% for key, value in properties %}
            when {{value[:key] || key.id.stringify}}
              %found{key.id} = true
              %var{key.id} =
                {% if value[:converter] %}
                  {{value[:converter]}}.from_rs(%rs)
                {% elsif value[:nilable] || value[:default] != nil %}
                  %rs.read(::Union({{value[:type]}} | Nil))
                {% else %}
                  %rs.read({{value[:type]}})
                {% end %}
          {% end %}
          else
            %rs.read
        end
      end

      {% for key, value in properties %}
        {% unless value[:nilable] || value[:default] != nil %}
          if %var{key.id}.is_a?(Nil) && !%found{key.id}
            raise ::DB::MappingException.new("Missing result set attribute: {{(value[:key] || key).id}}")
          end
        {% end %}
      {% end %}

      {% for key, value in properties %}
        {% if value[:nilable] %}
          {% if value[:default] != nil %}
            @{{key.id}} = %found{key.id} ? %var{key.id} : {{value[:default]}}
          {% else %}
            @{{key.id}} = %var{key.id}
          {% end %}
        {% elsif value[:default] != nil %}
          @{{key.id}} = %var{key.id}.is_a?(Nil) ? {{value[:default]}} : %var{key.id}
        {% else %}
          @{{key.id}} = %var{key.id}.as({{value[:type]}})
        {% end %}
      {% end %}
    end
  end
end
