require "../../spec_helper"
require "../../../src/core/converters/pg/numeric"

require "pg"

db = DB.open(ENV["DATABASE_URL"] || raise "No DATABASE_URL is set!")

describe Core::Converters::PG::Numeric do
  db.query_one("SELECT * FROM pg_numeric") do |rs|
    it "returns Float64 for PG::Numeric value" do
      converted = Core::Converters::PG::Numeric.from_rs(rs)
      converted.should be_a Float64
    end

    it "return Nil for NULL value" do
      converted = Core::Converters::PG::Numeric.from_rs(rs)
      converted.should be_nil
    end
  end
end
