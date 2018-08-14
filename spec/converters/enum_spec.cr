require "../spec_helper"
require "../../src/core/converters/enum"

require "pg"

db = DB.open(ENV["DATABASE_URL"] || raise "No DATABASE_URL is set!")

enum EnumSpecEnum
  Foo
  Bar
end

describe Core::Converters::Enum do
  db.query_one("SELECT * FROM enums") do |rs|
    it "returns Enum for existing value" do
      converted = Core::Converters::Enum(EnumSpecEnum).from_rs(rs)
      converted.should eq EnumSpecEnum::Bar
    end

    it "return Nil for NULL value" do
      converted = Core::Converters::Enum(EnumSpecEnum).from_rs(rs)
      converted.should be_nil
    end
  end
end
