require "../pg"
require "../../ext/pg/result_set"
require "json"

# Converts between the PostgreSQL's `"JSONB"` type and Crystal objects.
# It works the same way as the `JSON` converter does, but with `"JSONB"` type.
#
# OPTIMIZE: Refactor to extend the `JSON` module. Currently impossible due to https://github.com/crystal-lang/crystal/issues/7167.
module Onyx::SQL::Converters::PG::JSONB(T)
  def self.to_db(value : T) : DB::Any
    value.to_json
  end

  def self.from_rs(rs : DB::ResultSet) : T?
    bytes = rs.read_raw
    bytes.try do |bytes|
      T.from_json(String.new(bytes[1, bytes.bytesize - 1]))
    end
  end

  def self.from_rs_array(rs) : T?
    from_rs(rs)
  end
end
