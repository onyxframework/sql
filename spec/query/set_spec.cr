require "../spec_helper"

require "../../src/core/schema"
require "../../src/core/query"

module QuerySetSpec
  class User
    include Core::Schema
    schema :users do
      primary_key :id
      field :foo, String
      field :bar, String, key: :baz
    end
  end

  describe "Query::Instance#set" do
    context "with explicit clause" do
      context "witout params" do
        q = Core::Query.new(User).set("what")

        it "generates valid SQL" do
          q.to_s.should eq("UPDATE users SET what")
        end
      end

      context "with params" do
        q = Core::Query.new(User).set("what = ?", 42)

        it "generates valid SQL" do
          q.to_s.should eq("UPDATE users SET what = ?")
        end

        it "generates valid params" do
          q.params.should eq [42]
        end
      end
    end

    context "with hash arguments" do
      context "with fields with same keys" do
        q = Core::Query.new(User).set(id: 42, foo: "foo")

        it "generates valid SQL" do
          q.to_s.should eq "UPDATE users SET id = ?, foo = ?"
        end

        it "generates valid params" do
          q.params.should eq [42, "foo"]
        end
      end

      context "with fields with differnt keys" do
        q = Core::Query.new(User).set(id: 42, bar: "bar")

        it "generates valid SQL" do
          q.to_s.should eq "UPDATE users SET id = ?, baz = ?"
        end

        it "generates valid params" do
          q.params.should eq [42, "bar"]
        end
      end
    end

    context "when called multiple times" do
      q = Core::Query.new(User).set("what = random() * ?", 5).set(id: 42).set(bar: "baz")

      it "generates valid SQL" do
        q.to_s.should eq "UPDATE users SET what = random() * ?, id = ?, baz = ?"
      end

      it "generates valid params" do
        q.params.should eq [5, 42, "baz"]
      end
    end
  end
end
