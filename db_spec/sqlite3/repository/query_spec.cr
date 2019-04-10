require "../sqlite3_spec"
require "../../repository_spec"
require "../models"

describe "Repository(Postgres)#query" do
  repo = repo(:sqlite3)

  # This is John
  #

  user = uninitialized User

  describe "insert" do
    context "with a simple model" do
      user = User.new(
        name: "John",
        active: true,
      )

      cursor = repo.exec(user.insert)
      user = repo.query(User.where(id: cursor.last_insert_id.to_i32).select(:id).select(User)).first

      it "returns instance" do
        user.should be_a(User)
      end
    end
  end

  # And this is John's referrer, Jake
  #

  cursor = repo.exec(User.insert(name: "Jake"))
  referrer = repo.query(User.where(id: cursor.last_insert_id.to_i32).select(:id).select(User)).first

  describe "update" do
    context "with attributes" do
      # We're updating John's balance and activity status
      #

      query = User.query
        .update
        .set(active: false)
        .set(balance: 100.0_f32, updated_at: nil)
        .where(id: user.id.not_nil!)

      repo.exec(query)
      user = repo.query(User.where(id: user.id.not_nil!).select(:id, :balance)).first

      it "preloads attributes" do
        user.balance.should eq 100.0
      end
    end

    context "with direct references" do
      # We're setting John's referrer to Jake
      #

      query = User.update.set(referrer: referrer).where(id: user.id.not_nil!)
      cursor = repo.exec(query)

      it do
        cursor.rows_affected.should eq 1
      end
    end
  end

  describe "where" do
    user = repo.query(User.where(id: user.id.not_nil!).and_where(balance: 100.0_f32).select(:id).select(User)).first

    it "returns a User instance" do
      user.name.should eq "John"
    end

    context "with direct non-enumerable join" do
      query = User.query
        .select(:name, :id)
        .where(id: user.id.not_nil!)
        .join(referrer: true) do |q|
          q.select("referrer.*")
        end

      user = repo.query(query).first

      it "returns a User instance" do
        user.name.should eq "John"
      end

      it "preloads direct references" do
        user.referrer.not_nil!.name.should eq "Jake"
      end
    end
  end

  cursor = repo.exec(Tag.insert(content: "foo"))
  tag = repo.query(Tag.where(id: cursor.last_insert_id.to_i32).select(:id).select(Tag)).first
  post = uninitialized Post

  describe "insert" do
    context "with complex model" do
      cursor = repo.exec(Post.insert(author: user, tags: [tag], content: "Blah-blah"))
      post = repo.query(Post.where(id: cursor.last_insert_id.to_i32).select(:id).select(Post)).first

      it "returns model instance" do
        post.should be_a(Post)
      end

      it "preloads direct non-enumerable references" do
        post.author.not_nil!.id.should eq user.id
        post.author.not_nil!.name.should be_nil
      end

      it "preloads direct enumerable references" do
        post.tags.not_nil!.size.should eq 1
        post.tags.not_nil!.first.id.should eq tag.id
        post.tags.not_nil!.first.not_nil!.content.should be_nil
      end
    end

    context "multiple instances" do
      posts = [
        Post.new(author: user, tags: [tag], content: "Foo"),
        Post.new(author: user, content: "Bar"),
      ]

      cursor = repo.exec(posts.insert)
      cursor.rows_affected.should eq 2
    end
  end

  cursor = repo.exec(User.insert(name: "James"))
  new_user = repo.query(User.where(id: cursor.last_insert_id.to_i32).select(:id).select(User)).first

  describe "update" do
    context "with complex reference updates" do
      changeset = post.changeset

      changeset.update(tags: [] of Tag, editor: new_user)
      changeset.update(created_at: Time.now)

      cursor = repo.exec(post.update(changeset))

      it do
        cursor.rows_affected.should eq 1
      end
    end
  end

  describe "where" do
    context "with foreign non-enumerable join" do
      post = repo.query(Post.query
        .select(:id)
        .select(Post)
        .where(id: post.id.not_nil!)

        .join author: true do |q|
          q.select("author.rowid")
        end

        .join editor: true do |q|
          q.select(:id)
        end
      ).first

      it "returns model instance" do
        post.should be_a(Post)
      end

      it "preloads references" do
        post.author.not_nil!.id.should eq user.id
        post.editor.not_nil!.id.should eq new_user.id
      end
    end
  end

  describe "#delete" do
    it do
      cursor = repo.exec(post.delete.returning(:id))
      cursor.rows_affected.should eq 1
    end
  end
end
