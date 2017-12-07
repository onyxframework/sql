require "../query_spec"

module Query::SelectSpec
  class User < Core::Model
    schema :users do
    end
  end

  describe "#select" do
    context "with single argument" do
      it do
        sql = <<-SQL
          SELECT DISTINCT id FROM users
        SQL

        Query(User).select(:"DISTINCT id").to_s.should eq(sql.strip)
      end
    end

    context "with multiple arguments" do
      sql = <<-SQL
        SELECT name, role FROM users
      SQL

      context "passed as separate symbols" do
        it do
          Query(User).select(:name, :role).to_s.should eq(sql.strip)
        end
      end

      context "passed as array of symbols" do
        it do
          Query(User).select([:name, :role]).to_s.should eq(sql.strip)
        end
      end
    end

    context "when called multiple times" do
      it "rewrites to the last value" do
        sql = <<-SQL
          SELECT name FROM users
        SQL

        Query(User).select(:id).select(:name).to_s.should eq(sql.strip)
      end
    end
  end
end
