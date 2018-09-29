require "../models"

describe "Atom::Query#delete" do
  it do
    uuid = UUID.random

    q = Atom::Query(User).new.delete.where(uuid: uuid)

    q.to_s.should eq <<-SQL
    DELETE FROM users WHERE (users.uuid = ?)
    SQL

    q.params.should eq [uuid.to_s]
  end
end
