require "../models"

describe "Atom::Query#order_by" do
  context "with attribute argument" do
    it do
      q = Atom::Query(User).new.order_by(:active, :desc)

      q.to_s.should eq <<-SQL
      SELECT users.* FROM users ORDER BY users.activity_status DESC
      SQL

      q.params.should be_nil
    end
  end

  context "with string argument" do
    it do
      q = Atom::Query(User).new.order_by("some_column")

      q.to_s.should eq <<-SQL
      SELECT users.* FROM users ORDER BY some_column ASC
      SQL

      q.params.should be_nil
    end
  end
end
