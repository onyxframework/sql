require "../models"

describe "Query#update" do
  it do
    uuid = UUID.random
    ref_uuid = UUID.random

    q = Core::Query(User).new.update.set(name: "John", active: DB::Default).set(referrer: User.new(uuid: ref_uuid)).where(uuid: uuid)

    q.to_s.should eq <<-SQL
    UPDATE users SET name = ?, activity_status = DEFAULT, referrer_uuid = ? WHERE (users.uuid = ?)
    SQL

    q.params.should eq ["John", ref_uuid.to_s, uuid.to_s]
  end
end
