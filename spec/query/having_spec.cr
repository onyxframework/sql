require "../query_spec"

describe Query do
  describe "complex having" do
    it do
      query = Query(User).having(id: 42).and("char_length(name) > ?", [3]).or(role: User::Role::Admin, name: !nil)

      query.to_s.should eq <<-SQL
      SELECT * FROM users HAVING (users.id = ?) AND (char_length(name) > ?) OR (users.role = ? AND users.name IS NOT NULL)
      SQL

      query.params.should eq([42, 3, 1])
    end
  end

  describe "having" do
    context "with named arguments" do
      context "with one clause" do
        it do
          query = Query(User).having(id: 42)

          query.to_s.should eq <<-SQL
          SELECT * FROM users HAVING (users.id = ?)
          SQL

          query.params.should eq([42])
        end
      end

      context "with multiple clauses" do
        it do
          query = Query(User).having(id: 42, name: nil)

          query.to_s.should eq <<-SQL
          SELECT * FROM users HAVING (users.id = ? AND users.name IS NULL)
          SQL

          query.params.should eq([42])
        end
      end

      context "with multiple calls" do
        it do
          query = Query(User).having(id: 42, name: nil).having(role: User::Role::Admin)

          query.to_s.should eq <<-SQL
          SELECT * FROM users HAVING (users.id = ? AND users.name IS NULL) AND (users.role = ?)
          SQL

          query.params.should eq([42, 1])
        end
      end

      context "with reference" do
        user = User.new(id: 42)

        it do
          query = Query(Post).having(author: user)

          query.to_s.should eq <<-SQL
          SELECT * FROM posts HAVING (posts.author_id = ?)
          SQL

          query.params.should eq([42])
        end

        expect_raises ArgumentError do
          query = Query(Post).having(writer: user)
          query.to_s
        end
      end

      context "with nil reference" do
        it do
          query = Query(Post).having(author: nil)

          query.to_s.should eq <<-SQL
          SELECT * FROM posts HAVING (posts.author_id IS NULL)
          SQL
        end
      end

      context "with reference key" do
        user = User.new(id: 42)

        it do
          query = Query(Post).having(author_id: user.id)

          query.to_s.should eq <<-SQL
          SELECT * FROM posts HAVING (posts.author_id = ?)
          SQL

          query.params.should eq([42])
        end

        expect_raises ArgumentError do
          query = Query(Post).having(writer_id: user.id)
          query.to_s
        end
      end
    end

    context "with string argument" do
      context "with params" do
        it do
          query = Query(User).having("char_length(name) > ?", [3])

          query.to_s.should eq <<-SQL
          SELECT * FROM users HAVING (char_length(name) > ?)
          SQL

          query.params.should eq([3])
        end
      end

      context "without params" do
        it do
          query = Query(User).having("name IS NOT NULL")

          query.to_s.should eq <<-SQL
          SELECT * FROM users HAVING (name IS NOT NULL)
          SQL

          query.params.empty?.should be_truthy
        end
      end
    end
  end

  describe "#or_having" do
    it do
      query = Query(User).having(id: 42, name: nil).or_having(role: User::Role::Admin)

      query.to_s.should eq <<-SQL
      SELECT * FROM users HAVING (users.id = ? AND users.name IS NULL) OR (users.role = ?)
      SQL

      query.params.should eq([42, 1])
    end
  end

  describe "#and_having" do
    it do
      query = Query(User).having(id: 42, name: nil).and_having(role: User::Role::Admin)

      query.to_s.should eq <<-SQL
      SELECT * FROM users HAVING (users.id = ? AND users.name IS NULL) AND (users.role = ?)
      SQL

      query.params.should eq([42, 1])
    end
  end
end
