require "../models"

describe "Query#insert" do
  context "with minimum arguments" do
    it do
      q = Core::Query(User).new.insert(name: "John")

      q.to_s.should eq <<-SQL
      INSERT INTO users (name) VALUES (?)
      SQL

      q.params.should eq ["John"]
    end
  end

  context "with many arguments" do
    it do
      ref_uuid = UUID.random

      q = Core::Query(User).new.insert(referrer: User.new(uuid: ref_uuid), active: DB::Default, role: User::Role::Moderator, permissions: [User::Permission::EditPosts], name: "John")

      q.to_s.should eq <<-SQL
      INSERT INTO users (referrer_uuid, role, permissions, name) VALUES (?, ?, ?, ?)
      SQL

      q.params.should eq [ref_uuid.to_s, "moderator", ["edit_posts"], "John"]
    end
  end
end
