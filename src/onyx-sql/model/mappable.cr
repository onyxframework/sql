# This module allows to map a `Model` **to** the database.
module Onyx::SQL::Model::Mappable(T)
  # Return a `Tuple` of DB-ready values. It respects `Field` and `Reference` annotations,
  # also working with `Converter`s.
  #
  # It ignores `not_null` option. It will call `.not_nil!` on enumerable references'
  # primary keys, thus can raise `NilAssertionError`.
  #
  # ```
  # User.db_values(id: user.id)  # => {42}
  # User.db_values(foo: "bar")   # => Compilation-time error: unknown User instance variable foo
  # Post.db_values(author: user) # => May raise NilAssertionError if `user.id` is `nil`
  # ```
  def self.db_values(**values : **U) : Tuple forall U
  end

  # Return a instance *variable* SQL column name.
  #
  # ```
  # User.db_column(:id)      # "id"
  # User.db_column(:unknown) # Compilation-time error
  # ```
  def self.db_column(variable : T::Field | T::Reference) : String
  end

  macro included
    def self.db_values(**values : **U) : Tuple forall U
      {% verbatim do %}
        {% begin %}
          return {
            {% for key, value in U %}
              {% found = false %}

              {% for ivar in @type.instance_vars %}
                {% if ann = ivar.annotation(Onyx::SQL::Reference) %}
                  {% if key == ivar.name %}
                    {%
                      found = true

                      type = ivar.type.union_types.find { |t| t != Nil }
                      enumerable = false

                      if type <= Enumerable
                        enumerable = true
                        type = type.type_vars.first
                      end

                      options = type.annotation(Onyx::SQL::Model::Options)
                      raise "Onyx::SQL::Model::Options annotation must be defined for #{type}" unless options

                      pk = options[:primary_key]
                      raise "#{type} must have Onyx::SQL::Model::Options annotation with :primary_key option" unless pk

                      pk_rivar = type.instance_vars.find { |riv| "@#{riv.name}".id == pk.id }
                      raise "Cannot find primary key field #{pk} in #{type}" unless pk_rivar

                      pk_type = pk_rivar.type.union_types.find { |t| t != Nil }
                      converter = (a = pk_rivar.annotation(Onyx::SQL::Field)) && a[:converter]
                    %}

                    {% if enumerable %}
                      {% val = "values[#{key.symbolize}].try &.map(&.#{pk_rivar.name}.not_nil!)".id %}
                    {% else %}
                      {% val = "values[#{key.symbolize}].try &.#{pk_rivar.name}".id %}
                    {% end %}

                    {% if converter %}
                      {{val}}.try { |v| {{converter}}.to_db(v).as(DB::Any) },
                    {% elsif pk_type <= DB::Any %}
                      {% if enumerable %}
                        {% raise "Cannot implicitly map enumerable reference #{@type}@#{ivar.name} to DB::Any. Consider applying a converter with `#to_db(Array(#{pk_type}))` method to #{type}@#{pk_rivar.name} to make it work" %}
                      {% else %}
                        {{val}}.as(DB::Any),
                      {% end %}
                    {% else %}
                      {% raise "Cannot implicitly map reference #{@type}@#{ivar.name} to DB::Any. Consider applying a converter with `#to_db(#{pk_type})` method to #{type}@#{pk_rivar.name} to make it work" %}
                    {% end %}
                  {% end %}
                {% else %}
                  {% if key == ivar.name %}
                    {%
                      found = true
                      type = ivar.type.union_types.find { |t| t != Nil }
                      converter = (a = ivar.annotation(Onyx::SQL::Field)) && a[:converter]
                    %}

                    {% if converter %}
                      (values[{{key.symbolize}}].try do |val|
                        {{converter}}.to_db(val).as(DB::Any)
                      end),
                    {% elsif type <= DB::Any %}
                      values[{{key.symbolize}}].as(DB::Any),
                    {% else %}
                      {% raise "Cannot implicitly map #{@type}@#{ivar.name} to DB::Any. Consider applying a converter with `#to_db(#{type})` method to #{@type}@#{ivar.name} to make it work" %}
                    {% end %}
                  {% end %}
                {% end %}
              {% end %}

              {% raise "Cannot find an instance variable named @#{key} in #{@type}" unless found %}
            {% end %}
          }
        {% end %}
      {% end %}
    end

    def self.db_column(variable : T::Field | T::Reference) : String
      {% verbatim do %}
        {% begin %}
          if variable.is_a?(T::Field)
            case variable
            {% for ivar in @type.instance_vars.reject(&.annotation(Onyx::SQL::Reference)) %}
              when .{{ivar.name}}?
                {% key = ((a = ivar.annotation(Onyx::SQL::Field)) && a[:key]) || ivar.name %}
                return {{key.id.stringify}}
            {% end %}
            else
              raise "BUG: #{variable} is unmatched"
            end
          else
            case variable
            {% for ivar in @type.instance_vars.select(&.annotation(Onyx::SQL::Reference)) %}
              {% if ivar.annotation(Onyx::SQL::Reference)[:key] %}
                when .{{ivar.name}}?
                  return {{ivar.annotation(Onyx::SQL::Reference)[:key].id.stringify}}
              {% else %}
                when .{{ivar.name}}?
                  raise "Cannot map foreign {{@type}} reference @{{ivar.name}} to a DB column"
              {% end %}
            {% end %}
            else
              raise "BUG: #{variable} is unmatched"
            end
          end
        {% end %}
      {% end %}
    end
  end
end
