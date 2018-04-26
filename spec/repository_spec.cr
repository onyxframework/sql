require "db"
require "pg"

require "./spec_helper"
require "../src/core/repository"
require "../src/core/schema"
require "../src/core/query"
require "../src/core/converters/enum"
require "../src/core/logger/io"

alias Repo = Core::Repository

db = ::DB.open(ENV["DATABASE_URL"] || raise "No DATABASE_URL is set!")
logger = Core::Logger::IO.new(STDOUT)

module RepoSpec
  class User
    include Core::Schema
    include Core::Validation
    include Core::Query

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

      field :active, Bool, insert_nil: true
      field :role, Role, default: Role::User, converter: Core::Converters::Enum(Role)
      field :name, String

      created_at_field :created_at
      updated_at_field :updated_at
    end
  end

  class Post
    include Core::Schema
    include Core::Validation
    include Core::Query

    schema :posts do
      primary_key :id

      reference :author, User, key: :author_id
      reference :editor, User?, key: :editor_id

      field :the_content, String, key: :content

      created_at_field :created_at
      updated_at_field :updated_at
    end
  end

  repo = Repo.new(db, logger)
  user_created_at = uninitialized Time

  describe "#insert" do
    user = User.new(name: "Test User")
    user.id = repo.insert(user).as(Int64)

    it "sets created_at field" do
      user_created_at = repo.scalar(User.last.select(:created_at)).as(Time)
      user_created_at.should be_truthy
    end

    it "doesn't set updated_at field" do
      repo.scalar(User.last.select(:updated_at)).as(Time?).should be_nil
    end

    it "works with references" do
      post = Post.new(author: user, the_content: "Some content")
      repo.insert(post).should be_truthy
    end

    it "returns fresh id" do
      previous_id = repo.scalar(User.last.select(:id)).as(Int32)
      repo.insert(user).should eq(previous_id + 1)
    end

    it "works with multiple instances" do
      users = [User.new(name: "Foo"), User.new(name: "Bar")]
      repo.insert(users).should be_truthy
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
      complex_query = User
        .select("*", "COUNT (posts.id) AS posts_count")
        .join(:posts)
        .group_by("users.id", "posts.id")
        .order_by("users.id", :desc)
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
      user = repo.query(User.where(id: that_user_id)).first

      it "returns models with references" do
        post = repo.query(Post.where(author: user).join(:author, select: [:id, :name, :active, :role])).first
        author = post.author.not_nil!
        author.should eq user
        author.id.should eq that_user_id
        author.active.should be_true
        author.role.should eq(User::Role::User)
        author.name.should eq("Test User")
        author.created_at?.should be_nil
        author.updated_at.should be_nil
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
      users = repo.query_all(User.all)

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
      user = repo.query_one?(User.last)

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
      user = repo.query_one(User.last)

      it "returns a valid instance" do
        user.should be_a(User)
      end
    end
  end

  describe "#update" do
    user = repo.query_one(User.last)

    context "with Schema instance" do
      it "ignores empty changes" do
        repo.update(user).should eq nil
      end

      user.name = "Updated User"
      update = repo.update(user)
      updated_user = repo.query(User.last).first

      it "updates" do
        updated_user.name.should eq "Updated User"
      end
    end

    context "with Query instance" do
      update = repo.update(User.where(id: user.id).set(name: "Updated Again User"))
      updated_user = repo.query_one(User.last)

      it do
        updated_user.name.should eq "Updated Again User"
      end
    end
  end

  describe "#delete" do
    post = repo.query_one(Post.last)
    post_id = post.id

    context "with single Schema instance" do
      delete = repo.delete(post)

      it do
        delete.should be_truthy
        repo.query(Post.where(id: post_id)).empty?.should eq true
      end
    end

    context "with multiple Schema instances" do
      users = repo.query(User.order_by(:created_at, :desc).limit(2))
      delete = repo.delete(users)

      it do
        delete.should be_truthy
        repo.query(User.where(id: users.map(&.id))).empty?.should be_true
      end
    end

    context "with Query instance" do
      users = repo.query(User.order_by(:created_at, :desc).limit(2))
      delete = repo.delete(User.where(id: users.map(&.id)))

      it do
        delete.should be_truthy
        repo.query(User.where(id: users.map(&.id))).empty?.should be_true
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
      result = repo.exec(User.all)

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
      result = repo.scalar(User.last.select(:id)).as(Int32)

      it do
        result.should be_a(Int32)
      end
    end
  end
end
