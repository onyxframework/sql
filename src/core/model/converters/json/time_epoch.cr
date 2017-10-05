require "./converter"

module Core
  abstract class Model
    module Converters::JSON
      # Converts `Time` to the number of seconds elapsed since the unix epoch (00:00:00 UTC on 1 January 1970).
      #
      # ```
      # class User < Core::Model
      #   schema do
      #     created_at_field :created_at, json_converter: Converters::TimeEpoch
      #   end
      # end
      #
      # user.to_json # => {"created_at" => 1507179771}
      #
      # User.from_json(%q[{"created_at": 1507179771}]).created_at
      # # => 2017-10-05 05:02:51 UTC
      # ```
      class TimeEpoch < Converter(Time)
        def self.to_json(time : Time, json)
          time.epoch.to_json(json)
        end

        def self.from_json(pull_parser)
          Time.epoch(pull_parser.read_int.to_i64)
        end
      end
    end
  end
end
