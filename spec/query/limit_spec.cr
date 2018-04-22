require "../query_spec"

module Query::LimitSpec
  class User
    include Core::Schema

    schema :users do
    end
  end

  describe "#limit" do
    it do
      Query(User).limit(3).to_s.should eq <<-SQL
      SELECT * FROM users LIMIT 3
      SQL
    end
  end
end
