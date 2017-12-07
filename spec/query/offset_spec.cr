require "../query_spec"

module Query::OffsetSpec
  class User < Core::Model
    schema :users do
    end
  end

  describe "#offset" do
    it do
      Query(User).offset(0).to_s.should eq <<-SQL
      SELECT * FROM users OFFSET 0
      SQL
    end
  end
end
