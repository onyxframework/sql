module Core
  abstract class Model
    # A simple module which helps to validate models in a convenient (*enough*) way.
    module Validation
      # A simple `Array` of `Hash(Symbol, String)`.
      # NOTE: You have to call `#valid?` for `#errors` to refill.
      #
      # To reset use `errors.clear`. *Why do you need a separate method for this?*
      #
      # ```
      # user.name = nil
      # user.errors # => []
      # user.valid? # => false
      # user.errors # => [{:name => "must be present"}]
      # ```
      getter errors = [] of Hash(Symbol, String)

      # Check if there are any `#errors`.
      def valid?
        errors.empty?
      end

      # Define validation for a `Model`.
      #
      # ```
      # class User < Core::Model
      #   schema do
      #     field :name, String
      #   end
      #
      #   validation do
      #     errors.push({:name => "must be present"}) unless name
      #     errors.push({:name => "length must be > 3"}) unless name.try &.size.>3
      #   end
      # end
      #
      # User.new.valid? # => false
      # ```
      macro validation(&block)
        # Check if there are any `#errors`.
        def valid?
          errors.clear
          {{yield}}
          errors.empty?
        end
      end
    end
  end
end
