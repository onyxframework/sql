require "../models"

describe "Atom::Query#limit" do
  context "with int argument" do
    it do
      q = Atom::Query(User).new.limit(2)

      q.to_s.should eq <<-SQL
      SELECT users.* FROM users LIMIT ?
      SQL

      q.params.should eq [2]
    end
  end

  context "with nil argument" do
    it do
      q = Atom::Query(User).new.limit(nil)

      q.to_s.should eq <<-SQL
      SELECT users.* FROM users
      SQL

      q.params.should be_nil
    end
  end
end
