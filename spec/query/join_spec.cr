require "../models"

describe "Query#join" do
  context "explicit" do
    it do
      q = Core::Query(User).new.join("some_table", "users.some_keys @> some_table.key", type: :right)

      q.to_s.should eq <<-SQL
      SELECT users.* FROM users RIGHT JOIN some_table ON users.some_keys @> some_table.key
      SQL

      q.params.should be_nil
    end
  end

  context "with foreign reference" do
    context "without arguments" do
      it do
        q = Core::Query(User).new.join(:authored_posts)

        q.to_s.should eq <<-SQL
        SELECT users.* FROM users INNER JOIN posts AS authored_posts ON authored_posts.author_uuid = users.uuid
        SQL

        q.params.should be_nil
      end
    end

    context "with arguments" do
      it do
        q = Core::Query(User).new.join(:authored_posts, type: :right, as: "the_posts", select: {"created_at", "id"})

        q.to_s.should eq <<-SQL
        SELECT '' AS _authored_posts, the_posts.created_at, the_posts.id FROM users RIGHT JOIN posts AS the_posts ON the_posts.author_uuid = users.uuid
        SQL

        q.params.should be_nil
      end
    end
  end

  context "with direct reference" do
    it do
      q = Core::Query(Post).new.join(:author, type: :left, select: "id")

      q.to_s.should eq <<-SQL
      SELECT '' AS _author, author.id FROM posts LEFT JOIN users AS author ON posts.author_uuid = author.uuid
      SQL

      q.params.should be_nil
    end
  end
end
