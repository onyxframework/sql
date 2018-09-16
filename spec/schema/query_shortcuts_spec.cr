require "../query/**"

describe "Schema query shortcuts" do
  describe ".group_by" do
    it do
      User.group_by("foo", "bar").should eq Core::Query(User).new.group_by("foo", "bar")
    end
  end

  describe ".having" do
    it do
      User.having("foo").having("bar = ?", 42).should eq Core::Query(User).new.having("foo").having("bar = ?", 42)
    end
  end

  describe ".insert" do
    it do
      User.insert(name: "John").should eq Core::Query(User).new.insert(name: "John")
    end
  end

  describe ".limit" do
    it do
      User.limit(1).should eq Core::Query(User).new.limit(1)
    end
  end

  describe ".offset" do
    it do
      User.offset(1).should eq Core::Query(User).new.offset(1)
    end
  end

  describe ".set" do
    it do
      User.set(active: true).should eq Core::Query(User).new.set(active: true)
    end
  end

  describe ".where" do
    it do
      User.where(active: true).should eq Core::Query(User).new.where(active: true)
    end
  end

  {% for m in %w(update delete all one first last) %}
    describe {{m}} do
      it do
        User.{{m.id}}.should eq Core::Query(User).new.{{m.id}}
      end
    end
  {% end %}

  describe ".join" do
    context "with table" do
      it do
        Post.join("users", "author.id = posts.author_id", as: "author").should eq Core::Query(Post).new.join("users", "author.id = posts.author_id", as: "author")
      end
    end

    context "with reference" do
      it do
        Post.join(:author, select: {'*'}).should eq Core::Query(Post).new.join(:author, select: {'*'})
      end
    end
  end

  describe ".order_by" do
    it do
      User.order_by(:uuid, :asc).order_by("foo").should eq Core::Query(User).new.order_by(:uuid, :asc).order_by("foo")
    end
  end

  describe ".returning" do
    it do
      User.returning(:name).returning('*').should eq Core::Query(User).new.returning(:name).returning('*')
    end
  end

  describe ".select" do
    it do
      User.select(:name).select('*').should eq Core::Query(User).new.select(:name).select('*')
    end
  end

  describe "#insert" do
    it do
      User.new(name: "John").insert.should eq User.insert(name: "John", referrer: nil, updated_at: nil)
    end
  end

  describe "#update" do
    uuid = UUID.random
    user = User.new(uuid: uuid, name: "John")
    user.name = "Jake"

    it do
      user.update.should eq User.update.set(name: "Jake").where(uuid: uuid)
    end
  end

  describe "#delete" do
    uuid = UUID.random
    user = User.new(uuid: uuid, name: "John")

    it do
      user.delete.should eq User.delete.where(uuid: uuid)
    end
  end
end
