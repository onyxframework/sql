require "../spec_helper"

require "../../src/core/schema"
require "../../src/core/query"

module QueryOrderBySpec
  class User
    include Core::Schema

    schema :users do
      primary_key :id
      field :name, String, key: :the_name_column
    end
  end

  describe "#order_by" do
    it do
      Core::Query.new(User).order_by(:id, :desc).order_by(:name).order_by("custom_order").to_s.should eq <<-SQL
      SELECT users.* FROM users ORDER BY id DESC, the_name_column, custom_order
      SQL
    end
  end
end
