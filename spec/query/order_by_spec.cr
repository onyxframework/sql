require "../query_spec"

module Query::OrderBySpec
  class User < Core::Model
    schema :users do
    end
  end

  describe "#order_by" do
    context "with column only" do
      it do
        Query(User).order_by(:id).to_s.should eq <<-SQL
        SELECT * FROM users ORDER BY id
        SQL
      end
    end

    context "with column and order" do
      it do
        Query(User).order_by(:name, :DESC).to_s.should eq <<-SQL
        SELECT * FROM users ORDER BY name DESC
        SQL
      end
    end

    context "when called multiple times" do
      it "appends" do
        Query(User).order_by(:id, :DESC).order_by(:name).to_s.should eq <<-SQL
        SELECT * FROM users ORDER BY id DESC, name
        SQL
      end
    end
  end
end
