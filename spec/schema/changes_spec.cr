require "../models"

describe "Schema changes" do
  user = User.new

  it "has initially empty changes" do
    user.changes.empty?.should be_true
  end

  context "with scalar types" do
    it "tracks changes" do
      user.name = "Bar"
      user.changes.should eq ({"name" => "Bar"})

      user.active = false
      user.changes.should eq ({"name" => "Bar", "active" => false})
    end

    user.changes.clear

    it "ignores when not changed" do
      user.name = "Bar"
      user.changes.empty?.should be_true
    end
  end

  context "with references" do
    referrer = User.new(uuid: UUID.random)
    user.changes.clear

    it "tracks changes" do
      user.referrer = referrer
      user.changes.should eq ({"referrer" => referrer})
    end

    user.changes.clear

    it "ignores when not changed" do
      user.referrer = referrer
      user.changes.empty?.should be_true
    end
  end

  context "with foreign references" do
    user.changes.clear

    it "ignores changes" do
      user.referrals = [User.new]
      user.changes.empty?.should be_true
    end
  end
end
