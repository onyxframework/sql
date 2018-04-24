require "../spec_helper"

require "../../src/core/schema"
require "../../src/core/query"

module QueryLimitSpec
  class User
    include Core::Schema
    schema :users { }
  end

  describe "#limit" do
    it do
      Core::Query.new(User).limit(3).to_s.should eq <<-SQL
      SELECT * FROM users LIMIT 3
      SQL
    end
  end
end
