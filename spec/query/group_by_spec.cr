require "../models"

describe "Atom::Query#group_by" do
  it do
    q = Atom::Query(User).new.group_by("foo", "bar")
    q.to_s.should eq <<-SQL
    SELECT users.* FROM users GROUP BY foo, bar
    SQL
  end
end
