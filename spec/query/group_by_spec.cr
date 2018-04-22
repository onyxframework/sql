require "../query_spec"

module Query::GroupBySpec
  class User
    include Core::Schema

    schema :users do
    end
  end

  describe "#group_by" do
    it do
      Query(User).group_by(:"foo.id", :"bar.id").to_s.should eq <<-SQL
      SELECT * FROM users GROUP BY foo.id, bar.id
      SQL
    end
  end
end
