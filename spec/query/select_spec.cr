require "../models"

describe "Query#select" do
  it do
    q = Core::Query(User).new.select(:active, "foo")

    q.to_s.should eq <<-SQL
    SELECT users.activity_status, foo FROM users
    SQL

    q.params.should be_nil
  end
end
