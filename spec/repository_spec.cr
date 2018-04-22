require "db"
require "pg"

require "./spec_helper"
require "../src/core/repository"
require "../src/core/schema"

alias Repo = Core::Repository

db = ::DB.open(ENV["DATABASE_URL"] || raise "No DATABASE_URL is set!")
query_logger = Core::QueryLogger.new(nil)

module RepoSpec
  class User
    include Core::Schema

    enum Role
      User
      Admin
    end

    schema :users do
      primary_key :id

      reference :referrer, User, key: :referrer_id
      reference :referrals, Array(User), foreign_key: :referrer_id

      reference :posts, Array(Post), foreign_key: :author_id
      reference :edited_posts, Array(Post), foreign_key: :editor_id

      field :active, Bool, default: true
      field :role, Role, default: Role::User, converter: Core::Converters::Enum(Role)
      field :name, String

      created_at_field :created_at
      updated_at_field :updated_at
    end
  end

  class Post
    include Core::Schema

    schema :posts do
      primary_key :id

      reference :author, User, key: :author_id
      reference :editor, User?, key: :editor_id

      field :content, String

      created_at_field :created_at
      updated_at_field :updated_at
    end
  end

  repo = Repo.new(db, query_logger)
  user_created_at = uninitialized Time

  describe "#insert" do
    user = User.new(name: "Test User")
    user.id = repo.insert(user).as(Int64)

    it "sets created_at field" do
      user_created_at = repo.scalar(Query(User).last.select(:created_at)).as(Time)
      user_created_at.should be_truthy
    end

    it "doesn't set updated_at field" do
      repo.scalar(Query(User).last.select(:updated_at)).as(Time?).should be_nil
    end

    it "works with references" do
      post = Post.new(author: user, content: "Some content")
      repo.insert(post).should be_truthy
    end

    it "returns fresh id" do
      previous_id = repo.scalar(Query(User).last.select(:id)).as(Int32)
      repo.insert(user).should eq(previous_id + 1)
    end
  end

  describe "#query" do
    context "with SQL" do
      user = repo.query(User, "SELECT * FROM users WHERE id = ?", 1).first

      it "returns a valid instance" do
        user.id.should be_a(Int32)
      end
    end

    that_user_id = uninitialized Int64 | Int32 | Nil

    context "with Query" do
      complex_query = Query(User)
        .select(:*, :"COUNT (posts.id) AS posts_count")
        .join(:posts)
        .group_by(:"users.id", :"posts.id")
        .order_by(:"users.id DESC")
        .limit(1)

      user = repo.query(complex_query).first
      that_user_id = user.id

      it "returns a valid instance" do
        user.id.should be_a(Int32)
        user.active.should be_true
        user.role.should eq(User::Role::User)
        user.name.should eq("Test User")
        user.created_at.should be_a(Time)
        user.updated_at.should eq(nil)
      end
    end

    context "with references" do
      user = repo.query(Query(User).where(id: that_user_id)).first

      it "returns models with references" do
        post = repo.query(Query(Post).where(author: user).join(:author)).first
        author = post.author.not_nil!
        author.should eq user
        author.id.should eq that_user_id
        author.active.should be_true
        author.role.should eq(User::Role::User)
        author.name.should eq("Test User")
        author.created_at.should be_a(Time)
        author.updated_at.should eq(nil)
      end
    end

    pending "handles DB errors" do
      expect_raises do
        repo.query("INVALID QUERY")
      end
    end
  end

  describe "#query_all" do
    context "with SQL" do
      users = repo.query_all(User, "SELECT * FROM users WHERE id = ?", 1)

      it "returns valid instances" do
        users.should be_a(Array(User))
        users.first.id.should eq(1)
      end
    end

    context "with Query" do
      users = repo.query_all(Query(User).all)

      it "returns valid instances" do
        users.should be_a(Array(User))
      end
    end
  end

  describe "#query_one?" do
    context "with SQL" do
      user = repo.query_one?(User, "SELECT * FROM users WHERE id = ?", -1)

      it "returns a valid instance" do
        user.should be_a(User?)
      end
    end

    context "with Query" do
      user = repo.query_one?(Query(User).last)

      it "returns a valid instance" do
        user.should be_a(User?)
      end
    end
  end

  describe "#query_one" do
    context "with SQL" do
      user = repo.query_one(User, "SELECT * FROM users WHERE id = ?", 1)

      it "returns a valid instance" do
        user.should be_a(User)
        user.id.should eq(1)
      end

      it "raises on zero results" do
        expect_raises Core::Repository::NoResultsError do
          user = repo.query_one(User, "SELECT * FROM users WHERE id = ?", -1)
        end
      end
    end

    context "with Query" do
      user = repo.query_one(Query(User).last)

      it "returns a valid instance" do
        user.should be_a(User)
      end
    end
  end

  describe "#update" do
    user = repo.query(Query(User).last).first

    it "ignores empty changes" do
      repo.update(user).should eq nil
    end

    pending "handles DB errors" do
      user.id = nil
      expect_raises do
        repo.update(user)
      end
    end

    user.name = "Updated User"
    update = repo.update(user)
    updated_user = repo.query(Query(User).last).first

    it "actually updates" do
      updated_user.name.should eq "Updated User"
    end

    pending "returns an amount of affected rows" do
      update.should eq(1)
    end
  end

  describe "#delete" do
    post = repo.query(Query(Post).last).first
    post_id = post.id
    delete = repo.delete(post)

    it do
      delete.should be_truthy
      repo.query(Query(Post).where(id: post_id)).empty?.should eq true
    end

    pending "returns an amount of affected rows" do
      delete.should eq(1)
    end

    pending "handles DB errors" do
      # It's already deleted, so
      expect_raises do
        repo.delete(post)
      end
    end
  end

  describe "#exec" do
    context "with SQL" do
      result = repo.exec("SELECT 'Hello world'")

      it do
        result.should be_a(DB::ExecResult)
      end
    end

    context "with Query" do
      result = repo.exec(Query(User).all)

      it do
        result.should be_a(DB::ExecResult)
      end
    end
  end

  describe "#scalar" do
    context "with SQL" do
      result = repo.scalar("SELECT 1").as(Int32)

      it do
        result.should eq(1)
      end
    end

    context "with Query" do
      result = repo.scalar(Query(User).last.select(:id)).as(Int32)

      it do
        result.should be_a(Int32)
      end
    end
  end
end
