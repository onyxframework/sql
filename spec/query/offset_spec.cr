require "../query_spec"

describe Query do
  describe "#offset" do
    it do
      Query(User).offset(0).to_s.should eq <<-SQL
      SELECT * FROM users OFFSET 0
      SQL
    end
  end
end
