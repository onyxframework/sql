require "../models"

describe "Query#offset" do
  context "with int argument" do
    it do
      q = Core::Query(User).new.offset(2)

      q.to_s.should eq <<-SQL
      SELECT users.* FROM users OFFSET ?
      SQL

      q.params.should eq [2]
    end
  end

  context "with nil argument" do
    it do
      q = Core::Query(User).new.offset(nil)

      q.to_s.should eq <<-SQL
      SELECT users.* FROM users
      SQL

      q.params.should be_nil
    end
  end
end
