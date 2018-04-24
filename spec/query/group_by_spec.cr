require "../spec_helper"

require "../../src/core/schema"
require "../../src/core/query"

module QueryGroupBySpec
  class User
    include Core::Schema
    schema :users { }
  end

  describe "#group_by" do
    it do
      Core::Query.new(User).group_by("foo.id", "bar.id").to_s.should eq <<-SQL
      SELECT * FROM users GROUP BY foo.id, bar.id
      SQL
    end
  end
end
