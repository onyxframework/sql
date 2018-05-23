require "../spec_helper"

require "../../src/core/schema"
require "../../src/core/query"

module QueryOffsetSpec
  class User
    include Core::Schema
    schema :users { }
  end

  describe "#offset" do
    it do
      Core::Query.new(User).offset(0).to_s.should eq <<-SQL
      SELECT users.* FROM users OFFSET 0
      SQL
    end
  end
end
