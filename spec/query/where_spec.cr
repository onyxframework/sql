require "../query_spec"
require "../../src/core/converters/enum"

module Query::WhereSpec
  class User
    include Core::Schema

    enum Role
      User
      Admin
    end

    schema :users do
      primary_key :id
      field :role, Role, converter: Converters::Enum(Role)
      field :name, String
    end
  end

  class Post
    include Core::Schema

    schema :posts do
      reference :author, User, key: :author_id
    end
  end

  describe "complex where" do
    it do
      query = Query(User).where(id: 42).and("char_length(name) > ?", [3]).or(role: User::Role::Admin, name: !nil)

      query.to_s.should eq <<-SQL
      SELECT * FROM users WHERE (users.id = ?) AND (char_length(name) > ?) OR (users.role = ? AND users.name IS NOT NULL)
      SQL

      query.params.should eq([42, 3, 1])
    end
  end

  describe "where" do
    context "with named arguments" do
      context "with one clause" do
        it do
          query = Query(User).where(id: 42)

          query.to_s.should eq <<-SQL
          SELECT * FROM users WHERE (users.id = ?)
          SQL

          query.params.should eq([42])
        end
      end

      context "with multiple clauses" do
        it do
          query = Query(User).where(id: 42, name: nil)

          query.to_s.should eq <<-SQL
          SELECT * FROM users WHERE (users.id = ? AND users.name IS NULL)
          SQL

          query.params.should eq([42])
        end
      end

      context "with multiple calls" do
        it do
          query = Query(User).where(id: 42, name: nil).where(role: User::Role::Admin)

          query.to_s.should eq <<-SQL
          SELECT * FROM users WHERE (users.id = ? AND users.name IS NULL) AND (users.role = ?)
          SQL

          query.params.should eq([42, 1])
        end
      end

      context "with reference" do
        user = User.new(id: 42)

        it do
          query = Query(Post).where(author: user)

          query.to_s.should eq <<-SQL
          SELECT * FROM posts WHERE (posts.author_id = ?)
          SQL

          query.params.should eq([42])
        end

        expect_raises ArgumentError do
          query = Query(Post).where(writer: user)
          query.to_s
        end
      end

      context "with nil reference" do
        it do
          query = Query(Post).where(author: nil)

          query.to_s.should eq <<-SQL
          SELECT * FROM posts WHERE (posts.author_id IS NULL)
          SQL
        end
      end

      context "with reference key" do
        user = User.new(id: 42)

        it do
          query = Query(Post).where(author_id: user.id)

          query.to_s.should eq <<-SQL
          SELECT * FROM posts WHERE (posts.author_id = ?)
          SQL

          query.params.should eq([42])
        end

        expect_raises ArgumentError do
          query = Query(Post).where(writer_id: user.id)
          query.to_s
        end
      end
    end

    context "with string argument" do
      context "with params" do
        it do
          query = Query(User).where("char_length(name) > ?", [3])

          query.to_s.should eq <<-SQL
          SELECT * FROM users WHERE (char_length(name) > ?)
          SQL

          query.params.should eq([3])
        end
      end

      context "without params" do
        it do
          query = Query(User).where("name IS NOT NULL")

          query.to_s.should eq <<-SQL
          SELECT * FROM users WHERE (name IS NOT NULL)
          SQL

          query.params.empty?.should be_truthy
        end
      end
    end
  end

  describe "#or_where" do
    it do
      query = Query(User).where(id: 42, name: nil).or_where(role: User::Role::Admin)

      query.to_s.should eq <<-SQL
      SELECT * FROM users WHERE (users.id = ? AND users.name IS NULL) OR (users.role = ?)
      SQL

      query.params.should eq([42, 1])
    end
  end

  describe "#and_where" do
    it do
      query = Query(User).where(id: 42, name: nil).and_where(role: User::Role::Admin)

      query.to_s.should eq <<-SQL
      SELECT * FROM users WHERE (users.id = ? AND users.name IS NULL) AND (users.role = ?)
      SQL

      query.params.should eq([42, 1])
    end
  end
end
