require "../spec_helper"

require "../../src/core/schema"
require "../../src/core/query"

module QueryOrderBySpec
  class User
    include Core::Schema
    schema :users { }
  end

  describe "#order_by" do
    context "with column only" do
      it do
        Core::Query.new(User).order_by(:id).to_s.should eq <<-SQL
        SELECT * FROM users ORDER BY id
        SQL
      end
    end

    context "with column and order" do
      it do
        Core::Query.new(User).order_by(:name, :DESC).to_s.should eq <<-SQL
        SELECT * FROM users ORDER BY name DESC
        SQL
      end
    end

    context "when called multiple times" do
      it "appends" do
        Core::Query.new(User).order_by(:id, :desc).order_by(:name).to_s.should eq <<-SQL
        SELECT * FROM users ORDER BY id DESC, name
        SQL
      end
    end
  end
end
