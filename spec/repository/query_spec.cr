require "../repository_spec"

describe Atom::Repository do
  db = MockDB.new
  repo = Atom::Repository.new(db)

  describe "#query" do
    context "with Query" do
      time = Time.now - 3.days
      result = repo.query(Atom::Query(User).new.select(:active).where("created_at > ?", time).last)

      it "calls #query with valid sql" do
        db.latest_query_sql.should eq <<-SQL
        SELECT users.activity_status FROM users WHERE (created_at > ?) ORDER BY users.uuid DESC LIMIT ?
        SQL
      end

      it "calls #query with valid params" do
        db.latest_query_params.should eq [time, 1]
      end

      it "returns model instance" do
        result.should be_a(Array(User))
      end
    end
  end
end
