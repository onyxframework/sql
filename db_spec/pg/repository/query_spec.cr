require "../pg_spec"
require "../../repository_spec"

describe "Repository(Postgres)#query" do
  repo = repo(:postgresql)

  context "with Query" do
    user = uninitialized User

    describe "insert" do
      context "with a simple model" do
        user = User.new(
          name: "John",
          active: (rand > 0.5 ? DB::Default : true),
          balance: DB::Default
        )

        user = repo.query(user.insert).first

        it "returns instance" do
          user.should be_a(User)
        end
      end
    end

    referrer = repo.query(User.insert(name: "Jake")).first

    describe "update" do
      context "with attributes" do
        user = repo.query(User.update.set(active: (rand > 0.5 ? DB::Default : false)).set(balance: 100.0_f32).where(uuid: user.uuid).returning(:uuid, :balance)).first

        it "preloads attributes" do
          user.uuid.should be_a(UUID)
          user.balance.should eq 100.0
        end
      end

      context "with direct references" do
        user = repo.query(User.update.set(referrer: referrer).where(uuid: user.uuid)).first

        it "preloads references" do
          user.referrer.not_nil!.uuid.should be_a(UUID)
        end
      end
    end

    describe "where" do
      user = repo.query(User.where(uuid: user.uuid).and_where(balance: 100.0_f32)).first

      it "returns instance" do
        user.should be_a(User)
      end

      context "with direct non-enumerable join" do
        user = repo.query(User
          .where(uuid: user.uuid)
          .join(:referrer, select: '*')
          .select(:name, :uuid)
        ).first

        it "returns a User instance" do
          user.name.should eq "John"
        end

        it "preloads direct references" do
          user.referrer.not_nil!.name.should eq "Jake"
        end
      end
    end

    tag = repo.query(Tag.insert(content: "foo")).first
    post = uninitialized Post

    describe "insert" do
      context "with complex model" do
        post = repo.query(Post.insert(author: user, tags: [tag], content: "Blah-blah")).first

        it "returns model instance" do
          post.should be_a(Post)
        end

        it "preloads direct non-enumerable references" do
          post.author.uuid.should eq user.uuid
          post.author.name?.should be_nil
        end

        it "preloads direct enumerable references" do
          post.tags.size.should eq 1
          post.tags.first.id.should eq tag.id
          post.tags.first.content?.should be_nil
        end
      end
    end

    new_user = repo.query(User.insert(name: "James")).first

    describe "update" do
      context "with complex reference updates" do
        post.tags = [] of Tag
        post.editor = new_user
        post.created_at = DB::Default

        post = repo.query(post.update).first

        it "returns model instance" do
          post.should be_a(Post)
        end

        it "preloads direct non-enumerable references" do
          post.editor.not_nil!.uuid.should eq new_user.uuid
        end

        it "preloads direct enumerable references" do
          post.tags.size.should eq 0
        end
      end
    end

    describe "where" do
      context "with foreign non-enumerable join" do
        post = repo.query(Post
          .where(id: post.id).and("cardinality(tag_ids) = ?", 0)
          .join(:author, select: '*')
          .join(:editor, select: {"editor." + User.uuid})
        ).first

        it "returns model instance" do
          post.should be_a(Post)
        end

        it "preloads references" do
          post.author.uuid.should eq user.uuid
          post.editor.not_nil!.uuid.should eq new_user.uuid
        end
      end
    end
  end
end
