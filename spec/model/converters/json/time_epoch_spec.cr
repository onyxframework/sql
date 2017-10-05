require "../../../spec_helper"

class TimeEpochModel < Core::Model
  schema do
    field :some_time_field, Time, json_converter: Converters::JSON::TimeEpoch
  end
end

describe Core::Model::Converters::JSON::TimeEpoch do
  it do
    time = Time.now

    i = TimeEpochModel.new(some_time_field: time)
    json = i.to_json
    json.should eq(%q[{"some_time_field":%{epoch}}] % {epoch: time.epoch})

    TimeEpochModel.from_json(json).some_time_field.not_nil!.epoch.should eq time.epoch
  end
end
