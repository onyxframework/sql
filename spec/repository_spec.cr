require "db"
require "pg"

require "./spec_helper"
require "../src/core/repository"
require "../src/core/model"

alias Repo = Core::Repository

db = ::DB.open(ENV["DATABASE_URL"] || raise "No DATABASE_URL is set!")
query_logger = Core::QueryLogger.new(nil)

module RepoSpec
  class Post < Core::Model
  end

  class User < Core::Model
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

      field :role, Role, default: Role::User, converter: Core::Converters::Enum(Role)
      field :name, String

      created_at_field :created_at
      updated_at_field :updated_at
    end
  end

  class Post < Core::Model
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
    query = Query(User).last

    it "sets created_at field" do
      user_created_at = db.scalar(query.select(:created_at).to_s).as(Time)
      user_created_at.should be_truthy
    end

    it "doesn't set updated_at field" do
      db.scalar(query.select(:updated_at).to_s).as(Time?).should be_nil
    end

    it "works with references" do
      post = Post.new(author: user, content: "Some content")
      repo.insert(post).should be_truthy
    end

    it "returns fresh id" do
      previous_id = db.scalar(query.select(:id).to_s).as(Int32)
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

    context "with Query" do
      complex_query = Query(User)
        .select(:*, :"COUNT (posts.id) AS posts_count")
        .join(:posts)
        .group_by(:"users.id", :"posts.id")
        .order_by(:"users.id DESC")
        .limit(1)

      user = repo.query(complex_query).first

      it "returns a valid instance" do
        user.id.should be_a(Int32)
        user.role.should eq(User::Role::User)
        user.name.should eq("Test User")
        user.created_at.should be_a(Time)
        user.updated_at.should eq(nil)
      end
    end

    pending "handles DB errors" do
      expect_raises do
        repo.query("INVALID QUERY")
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
end
