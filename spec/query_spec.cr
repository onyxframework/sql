require "./spec_helper"

describe Query do
  pending "returns new instance every time a method is called" do
    # TODO: [RFC]
  end

  describe "#reset" do
    pending do
      query = Query(User).select(:*).order_by(:id).where("char_length(name) > ?", [1]).limit(3).offset(5).join(:posts).group_by(:"users.id", :"posts.id").having("COUNT (posts.id) > ?", [1])

      query.reset.to_s.should eq <<-SQL
      SELECT * FROM users
      SQL
    end
  end

  describe "#all" do
    describe "on instance" do
      it do
        query = Query(User).limit(3).offset(5)
        query.all.to_s.should eq <<-SQL
        SELECT * FROM users OFFSET 5
        SQL
      end
    end

    describe "on class" do
      it do
        Query(User).all.to_s.should eq <<-SQL
        SELECT * FROM users
        SQL
      end
    end
  end

  describe "#one" do
    it do
      Query(User).one.to_s.should eq <<-SQL
      SELECT * FROM users LIMIT 1
      SQL
    end
  end

  describe "#last" do
    it do
      Query(User).last.to_s.should eq <<-SQL
      SELECT * FROM users ORDER BY id DESC LIMIT 1
      SQL
    end
  end

  describe "#first" do
    it do
      Query(User).first.to_s.should eq <<-SQL
      SELECT * FROM users ORDER BY id ASC LIMIT 1
      SQL
    end
  end

  describe "#[]" do
    context "with one argument" do
      query = Query(User)[42]

      it "generates valid query" do
        query.to_s.should eq <<-SQL
        SELECT * FROM users WHERE (id = ?)
        SQL
      end

      it "generates valid params" do
        query.params.should eq [42]
      end
    end

    context "with multiple arguments" do
      query = Query(User)[42, 43]

      it "generates valid query" do
        query.to_s.should eq <<-SQL
        SELECT * FROM users WHERE (id IN (?, ?))
        SQL
      end

      it "generates valid params" do
        query.params.should eq [42, 43]
      end
    end
  end
end
