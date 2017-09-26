require "./spec_helper"

describe Core::Model do
  user = uninitialized User

  it do
    user = User.new(id: 42, name: "Vlad Faust", posts_count: 146)
  end

  describe "#db_fields" do
    it do
      user.db_fields.should eq({:id => 42, :name => "Vlad Faust", :created_at => nil, :updated_at => nil, :role => User::Role::User, :referrer_id => nil})
    end
  end

  post = uninitialized Post

  context "with references" do
    it "has reference properties" do
      post = Post.new(author: user, content: "Foobar")
      post.author.should eq user
      user.posts = [post]
      user.posts.not_nil!.should contain(post)
    end

    describe "#db_fields" do
      it do
        post.db_fields.should eq({
          :id         => nil,
          :author_id  => 42,
          :editor_id  => nil,
          :content    => "Foobar",
          :created_at => nil,
          :updated_at => nil,
        })
      end
    end

    context "referencing self" do
      referrer = uninitialized User
      referral = uninitialized User

      it do
        referrer = User.new(id: 44)
        referral = User.new(referrer: referrer)
        referral.referrer.should eq referrer
        referrer.referrals = [referral]
        referrer.referrals.not_nil!.should contain(referral)
      end

      describe "#db_fields" do
        it do
          referral.db_fields[:referrer_id].should eq 44
        end
      end
    end
  end

  describe "#changes" do
    it "is initially empty" do
      user.changes.empty?.should eq true
    end

    it "tracks changes" do
      user.name = "Updated User"
      user.changes.should eq({:name => "Updated User"})

      user.name = "Twice Updated User"
      user.changes.should eq({:name => "Twice Updated User"})
    end
  end

  describe "validation" do
    describe "#valid?" do
      it do
        Post.new.valid?.should eq true
        user.name = nil
        user.valid?.should eq false
        user.name = "foobar"
        user.valid?.should eq true
      end
    end

    describe "#errors" do
      it do
        user.errors.empty?.should eq true
        user.name = nil
        user.valid?
        user.errors.should eq([{:name => "length must be > 3"}])
      end
    end
  end
end
