require "../../spec_helper"
require "../../../src/core/converters/enum_array"

require "pg"

db = DB.open(ENV["DATABASE_URL"] || raise "No DATABASE_URL is set!")

enum EnumArraySpecEnum
  Foo
  Bar
  Baz
end

describe Core::Converters::EnumArray do
  db.query_each("SELECT * FROM enum_arrays") do |rs|
    it "returns array of enums from existing values" do
      converted = Core::Converters::EnumArray(EnumArraySpecEnum, Int16).from_rs(rs)
      converted.should eq [EnumArraySpecEnum::Bar, EnumArraySpecEnum::Baz]
    end

    it "returns Nil for NULL value" do
      converted = Core::Converters::EnumArray(EnumArraySpecEnum, Int32).from_rs(rs)
      converted.should be_nil
    end
  end
end
