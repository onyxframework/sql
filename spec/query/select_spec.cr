require "../spec_helper"

require "../../src/core/schema"
require "../../src/core/query"

module QuerySelectSpec
  class User
    include Core::Schema
    schema :users { }
  end

  describe "#select" do
    context "with single argument" do
      it do
        sql = <<-SQL
          SELECT DISTINCT id FROM users
        SQL

        Core::Query.new(User).select("DISTINCT id").to_s.should eq(sql.strip)
      end
    end

    context "with multiple arguments" do
      sql = <<-SQL
        SELECT name, role FROM users
      SQL

      context "passed as separate values" do
        it do
          Core::Query.new(User).select(:name, "role").to_s.should eq(sql.strip)
        end
      end
    end

    context "when called multiple times" do
      it "rewrites to the last value" do
        sql = <<-SQL
          SELECT id, name, role FROM users
        SQL

        Core::Query.new(User).select(:id).select("name, role").to_s.should eq(sql.strip)
      end
    end
  end
end
