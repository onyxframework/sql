require "../query_spec"

describe Query do
  describe "#limit" do
    it do
      Query(User).limit(3).to_s.should eq <<-SQL
      SELECT * FROM users LIMIT 3
      SQL
    end
  end
end
