require "../spec_helper"

require "../../src/core/schema"
require "../../src/core/query"

module QuerySelectSpec
  class User
    include Core::Schema
    include Core::Query

    schema :users do
      primary_key :id
      field :foo, String
      field :bar, String, key: :baz
    end
  end

  describe "Query::Instance#select" do
    context "with single argument" do
      q = User.select("DISTINCT id")

      it do
        q.to_s.should eq "SELECT DISTINCT id FROM users"
      end
    end

    context "with multiple arguments" do
      q = User.select(:bar, "role", "*")

      it do
        q.to_s.should eq "SELECT baz, role, * FROM users"
      end
    end

    context "when called multiple times" do
      q = User.select(:id).select(:foo, :bar).select("DISTINCT role")

      it do
        q.to_s.should eq "SELECT id, foo, baz, DISTINCT role FROM users"
      end
    end
  end
end
