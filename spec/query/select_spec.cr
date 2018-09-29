require "../models"

describe "Atom::Query#select" do
  it do
    q = Atom::Query(User).new.select(:active, "foo")

    q.to_s.should eq <<-SQL
    SELECT users.activity_status, foo FROM users
    SQL

    q.params.should be_nil
  end
end
