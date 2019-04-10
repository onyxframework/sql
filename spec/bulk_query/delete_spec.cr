require "../models"

describe "BulkQuery#delete" do
  it do
    uuid1 = UUID.random
    uuid2 = UUID.random

    user1 = User.new(uuid: uuid1)
    user2 = User.new(uuid: uuid2)

    q = [user1, user2].delete.returning(:uuid)

    sql, params = q.build

    sql.should eq <<-SQL
    DELETE FROM users WHERE uuid IN (?, ?) RETURNING users.uuid
    SQL

    params.to_a.should eq [uuid1.to_s, uuid2.to_s]
  end
end
