require "../../schema_spec"

module Schema::ChangesSpec
  class User
    include Core::Schema

    schema :users do
      primary_key :id
      reference :referrer, User, key: :referrer_id
      field :foo, String
      field :bar, Bool
    end
  end

  describe "#changes" do
    user = User.new(id: 42, foo: "Foo", bar: false)

    it "has initially empty changes" do
      user.changes.empty?.should be_true
    end

    context "with fields" do
      it "tracks changes" do
        user.id = 43
        user.changes.should eq ({:id => 43})

        user.foo = "Bar"
        user.changes.should eq ({:id => 43, :foo => "Bar"})

        user.bar = true
        user.changes.should eq ({:id => 43, :foo => "Bar", :bar => true})

        user.changes.clear
        user.changes.empty?.should be_true
      end

      it "ignores when not changed" do
        user.id = 43
        user.changes.empty?.should be_true
      end
    end

    context "with references" do
      it "tracks changes" do
        user.referrer = User.new(id: 44)
        user.referrer_id.should eq 44
        user.changes.should eq ({:referrer_id => 44})

        user.referrer = nil
        user.referrer_id.should eq nil
        user.changes.should eq ({:referrer_id => nil})
      end

      it "ignores when not changed" do
        user.referrer = User.new(id: 44)
        user.referrer_id.should eq 44
        user.changes.clear

        user.referrer = User.new(id: 44)
        user.referrer_id.should eq 44
        user.changes.empty?.should be_true
      end
    end
  end
end
