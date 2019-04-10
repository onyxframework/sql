require "../models"

describe "BulkQuery#insert" do
  it do
    uuid1 = UUID.random
    uuid2 = UUID.random

    user1 = User.new(uuid: uuid1, name: "John", active: true, favorite_numbers: [42, 43])
    user2 = User.new(name: "Jake", active: false, referrer: user1)

    q = [user1, user2].insert.returning(User)

    sql, params = q.build

    sql.should eq <<-SQL
    INSERT INTO users (uuid, activity_status, favorite_numbers, name, referrer_uuid) VALUES (?, ?, ?, ?, NULL), (DEFAULT, ?, DEFAULT, ?, ?) RETURNING users.*
    SQL

    params.to_a.should eq [
      uuid1.to_s, true, "42,43", "John",
      false, "Jake", uuid1.to_s,
    ]
  end
end
