require "../../schema_spec"

module Schema::ReferencesSpec
  class User
    include Core::Schema

    schema :users do
      primary_key :id
      reference :referrer, User, key: :referrer_id
      reference :referrals, Array(User), foreign_key: :referrer_id
      reference :posts, Array(Post), foreign_key: :author_id
      reference :likes, Array(Like), foreign_key: :user_id
    end
  end

  class Post
    include Core::Schema

    schema :posts do
      primary_key :id
      reference :author, User, key: :author_id
      reference :likes, Array(Like), foreign_key: :post_id
    end
  end

  class Like
    include Core::Schema

    schema :likes do
      reference :post, Post, key: :post_id
      reference :user, User, key: :user_id
    end
  end

  describe "schema references" do
    referrer = User.new(id: 42)

    user = uninitialized User
    post = uninitialized Post
    like = uninitialized Like
    user_copy = uninitialized User

    it "add references to initializer" do
      user = User.new(id: 43, referrer: referrer)
      post = Post.new(id: 17, author: referrer)
      like = Like.new(post: post, user: user)
      user_copy = User.new(id: user.id, referrer: referrer, likes: [like])
    end

    it "add keys to fields" do
      user.fields.should eq ({
        :id          => 43,
        :referrer_id => 42,
      })

      post.fields.should eq ({
        :id        => 17,
        :author_id => 42,
      })

      like.fields.should eq ({
        :post_id => 17,
        :user_id => 43,
      })

      user_copy.fields.should eq ({
        :id          => 43,
        :referrer_id => 42,
      })
    end

    it "gen named getters" do
      referrer.referrer.should be_nil
      referrer.referrals.should be_nil
      referrer.posts.should be_nil
      referrer.likes.should be_nil

      user.referrer.should eq referrer
      user.referrals.should be_nil
      user.posts.should be_nil
      user.likes.should be_nil

      post.author.should eq referrer
      post.likes.should be_nil

      like.post.should eq post
      like.user.should eq user

      user_copy.likes.should eq [like]
    end

    it "gen named setters" do
      referrer.posts = [post]
      referrer.posts.should eq [post]

      user.likes = [like]
      user.likes.should eq [like]

      post.likes = [like]
      post.likes.should eq [like]

      referrer.referrals = [user]
      referrer.referrals.should eq [user]

      user.referrer = User.new(id: 45)
      user.referrer.should_not eq referrer
    end

    it "gen fields" do
      referrer.referrer_id.should be_nil

      user.referrer_id.should eq 45
      post.author_id.should eq 42

      like.user_id.should eq 43
      like.post_id.should eq 17

      like.user_id = nil
      like.user_id.should be_nil
    end
  end
end
