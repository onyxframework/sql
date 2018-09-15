require "./mock_db"

describe Core::Repository do
  db = MockDB.new
  repo = Core::Repository.new(db)

  describe "#exec" do
    context "with paramsless Query" do
      result = repo.exec(Core::Query(User).new.update.set("foo = 42"))

      it "calls DB#exec with valid sql" do
        db.latest_exec_sql.should eq <<-SQL
        UPDATE users SET foo = 42
        SQL
      end

      it "does not pass any params to DB#exec" do
        db.latest_exec_params.should be_nil
      end
    end

    context "with params Query" do
      result = repo.exec(Core::Query(User).new.update.set(active: true))

      it "calls DB#exec with valid sql" do
        db.latest_exec_sql.should eq <<-SQL
        UPDATE users SET activity_status = ?
        SQL
      end

      it "pass params to DB#exec" do
        db.latest_exec_params.should eq [true]
      end
    end
  end
end
