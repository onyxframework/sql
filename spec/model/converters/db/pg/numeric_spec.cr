require "../../../../spec_helper"
require "../../../../../src/core/model/converters/db/pg/numeric"

require "pg"

db = DB.open(ENV["DATABASE_URL"] || raise "No DATABASE_URL is set!")
query_logger = Core::QueryLogger.new(nil)
repo = Repo.new(db, query_logger)

class PGNumericModel < Core::Model
  schema do
    table_name "pg_numeric_model"
    primary_key :id
    field :a_number, Float64, db_converter: Converters::DB::PG::Numeric
  end
end

describe Core::Model::Converters::DB::PG::Numeric do
  repo.insert(PGNumericModel.new(a_number: 42.0))

  it do
    repo.query(Query(PGNumericModel).all).first.a_number.should be_a(Float64)
  end
end
