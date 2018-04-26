module Core
  # A module which helps to validate models in a convenient way.
  #
  # It has to be included into a model **explicitly**.
  #
  # Implemented inline validations (defined as `:validate` option on field):
  # - *size* (`Range | Int32`) - Validate size;
  # - *min* (`Comparable`) - Check if field value `>=` than min;
  # - *max* (`Comparable`) - Check if field value `<=` than max;
  # - *min!* (`Comparable`) - Check if field value `>` than min;
  # - *max!* (`Comparable`) - Check if field value `<` than max;
  # - *in* (`Enumerable`) - Validate if field value is included in range or array etc.;
  # - *regex* (`Regex`) - Validate if field value matches regex;
  # - *custom* (`Proc`) - Custom validation, see example below;
  #
  # ```
  # class User
  #   include Core::Schema
  #   include Core::Validation
  #
  #   schema do
  #     field :name, String, validate: {
  #       size:   (3..32),
  #       regex:  /\w+/,
  #       custom: ->(name : String) {
  #         error!(:name, "Some condition not met") unless some_condition?(name)
  #       },
  #     }
  #     field :age, Int32?, validate: {in: (18..150)}
  #   end
  #
  #   validate do
  #     error!(:custom_field, "some error occured") unless some_condition
  #   end
  # end
  # ```
  #
  # NOTE: A `#nil?` validation will be run at first if the field is defined as non-nilable.
  module Validation
    macro define_validation
      getter errors = Array(Hash(Symbol, String)).new

      # Add an error to `errors`, stopping further validations.
      #
      # ```
      # field :name, String, validate: ->(n : String) { error!(:name, "invalid") }
      # ...
      # validate do
      #   error!(:name, "another error")
      #   will_not_be_called
      # end
      # ```
      protected def error!(field, description)
        @errors.push({field => description})
        raise Throw.new
      end

      # Check if the model is valid.
      def valid?
        validate
        @errors.empty?
      end

      # Ensure that the model is valid, otherwise raise `ValidationError`.
      def valid!
        raise ValidationError.new(self, @errors) unless valid?
        return self
      end

      # Execute validation; should be called manually, prefer `valid?`.
      def validate
        @errors.clear

        {% for _field in INTERNAL__CORE_FIELDS %}
          begin
            {{field = _field[:name]}}

            if @{{field.id}}.nil?
              if !{{_field[:nilable]}} && !({{_field[:insert_nil]}} && explicitly_initialized)
                error!({{field}}, "must not be nil")
              end
            else
              {% if validations = _field[:options][:validate] %}
                value = @{{field.id}}.not_nil!

                {% if validations[:size] %}
                  case size = {{validations[:size].id}}
                  when Int32
                    unless value.size == size
                      error!({{field}}, "must have exact size of #{size}")
                    end
                  when Range
                    unless (size).includes?(value.size)
                      error!({{field}}, "must have size in range of #{size}")
                    end
                  end
                {% end %}

                {% if validations[:in] %}
                  unless ({{validations[:in]}}).includes?(value)
                    error!({{field}}, "must be included in {{validations[:in].id}}")
                  end
                {% end %}

                {% if validations[:min] %}
                  unless value >= {{validations[:min]}}
                    error!({{field}}, "must be greater or equal to {{validations[:min].id}}")
                  end
                {% end %}

                {% if validations[:max] %}
                  unless value <= {{validations[:max]}}
                    error!({{field}}, "must be less or equal to {{validations[:max].id}}")
                  end
                {% end %}

                {% if validations[:min!] %}
                  unless value > {{validations[:min!]}}
                    error!({{field}}, "must be greater than {{validations[:min!].id}}")
                  end
                {% end %}

                {% if validations[:max!] %}
                  unless value < {{validations[:max!]}}
                    error!({{field}}, "must be less than {{validations[:max!].id}}")
                  end
                {% end %}

                {% if validations[:regex] %}
                  unless {{validations[:regex]}}.match(value)
                    error!({{field}}, "must match {{validations[:regex].id}}")
                  end
                {% end %}

                {% if validations[:custom] %}
                  {{validations[:custom].id}}.call(value)
                {% end %}
              {% end %}
            end
          rescue ex : Throw
          end
        {% end %}
      end
    end

    # Define a custom validations block, which will be run **after** inline validations.
    #
    # ```
    # class User
    #   validate do
    #     error!(:custom, "some condition failed") unless some_condition
    #   end
    # end
    # ```
    private macro validate(&block)
      def validate
        previous_def
        begin
          {{yield}}
        rescue ex : Throw
        end
      end
    end

    private class Throw < Exception
    end

    class ValidationError < Exception
      getter errors

      def initialize(@model, @errors : Hash(Symbol, String))
        super("#{@model} validation failed: #{@errors}")
      end
    end
  end
end
