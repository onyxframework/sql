require "./mock_db"

describe Core::Repository do
  db = MockDB.new
  repo = Core::Repository.new(db)

  describe "#scalar" do
    context "with paramsless Query" do
      result = repo.scalar(Core::Query(User).new.update.set("foo = 42").returning(User.uuid))

      it "calls DB#scalar with valid sql" do
        db.latest_scalar_sql.should eq <<-SQL
        UPDATE users SET foo = 42 RETURNING uuid
        SQL
      end

      it "does not pass any params to DB#scalar" do
        db.latest_scalar_params.should be_nil
      end
    end

    context "with params Query" do
      result = repo.scalar(Core::Query(User).new.update.set(active: true).returning(User.active))

      it "calls DB#scalar with valid sql" do
        db.latest_scalar_sql.should eq <<-SQL
        UPDATE users SET activity_status = ? RETURNING activity_status
        SQL
      end

      it "pass params to DB#scalar" do
        db.latest_scalar_params.should eq [true]
      end
    end
  end
end
