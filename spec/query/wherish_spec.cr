require "../query_spec"

describe Query do
  describe "complex #and & #or dispatching" do
    it do
      query = Query(User).where(id: [42, 43, 44]).having("char_length(name) > ?", [3]).and(role: User::Role::Admin).and_where(name: nil).or("id > ?", [24])

      query.to_s.should eq <<-SQL
      SELECT * FROM users WHERE (id IN (?, ?, ?)) AND (name IS NULL) OR (id > ?) HAVING (char_length(name) > ?) AND (role = ?)
      SQL

      query.params.should eq([42, 43, 44, 24, 3, 1])
    end
  end

  {% for wherish in %w(where having) %}
    describe "complex {{wherish.id}}" do
      it do
        query = Query(User).{{wherish.id}}(id: 42).and("char_length(name) > ?", [3]).or(role: User::Role::Admin, name: !nil)

        query.to_s.should eq <<-SQL
        SELECT * FROM users {{wherish.upcase.id}} (id = ?) AND (char_length(name) > ?) OR (role = ? AND name IS NOT NULL)
        SQL

        query.params.should eq([42, 3, 1])
      end
    end

    describe "{{wherish.id}}" do
      context "with named arguments" do
        context "with one clause" do
          it do
            query = Query(User).{{wherish.id}}(id: 42)

            query.to_s.should eq <<-SQL
            SELECT * FROM users {{wherish.upcase.id}} (id = ?)
            SQL

            query.params.should eq([42])
          end
        end

        context "with multiple clauses" do
          it do
            query = Query(User).{{wherish.id}}(id: 42, name: nil)

            query.to_s.should eq <<-SQL
            SELECT * FROM users {{wherish.upcase.id}} (id = ? AND name IS NULL)
            SQL

            query.params.should eq([42])
          end
        end

        context "with multiple calls" do
          it do
            query = Query(User).{{wherish.id}}(id: 42, name: nil).{{wherish.id}}(role: User::Role::Admin)

            query.to_s.should eq <<-SQL
            SELECT * FROM users {{wherish.upcase.id}} (id = ? AND name IS NULL) AND (role = ?)
            SQL

            query.params.should eq([42, 1])
          end
        end
      end

      context "with string argument" do
        context "with params" do
          it do
            query = Query(User).{{wherish.id}}("char_length(name) > ?", [3])

            query.to_s.should eq <<-SQL
            SELECT * FROM users {{wherish.upcase.id}} (char_length(name) > ?)
            SQL

            query.params.should eq([3])
          end
        end

        context "without params" do
          it do
            query = Query(User).{{wherish.id}}("name IS NOT NULL")

            query.to_s.should eq <<-SQL
            SELECT * FROM users {{wherish.upcase.id}} (name IS NOT NULL)
            SQL

            query.params.empty?.should be_truthy
          end
        end
      end
    end

    describe "#or_{{wherish.id}}" do
      context "with named arguments" do
        context "with one clause" do
          it do
            query = Query(User).or_{{wherish.id}}(id: 42)

            query.to_s.should eq <<-SQL
            SELECT * FROM users {{wherish.upcase.id}} (id = ?)
            SQL

            query.params.should eq([42])
          end
        end

        context "with multiple clauses" do
          it do
            query = Query(User).or_{{wherish.id}}(id: 42, name: nil)

            query.to_s.should eq <<-SQL
            SELECT * FROM users {{wherish.upcase.id}} (id = ? AND name IS NULL)
            SQL

            query.params.should eq([42])
          end
        end

        context "with multiple calls" do
          it do
            query = Query(User).or_{{wherish.id}}(id: 42, name: nil).or_{{wherish.id}}(role: User::Role::Admin)

            query.to_s.should eq <<-SQL
            SELECT * FROM users {{wherish.upcase.id}} (id = ? AND name IS NULL) OR (role = ?)
            SQL

            query.params.should eq([42, 1])
          end
        end
      end

      context "with string argument" do
        context "with params" do
          it do
            query = Query(User).{{wherish.id}}(id: 42).or_{{wherish.id}}("char_length(name) > ?", [3])

            query.to_s.should eq <<-SQL
            SELECT * FROM users {{wherish.upcase.id}} (id = ?) OR (char_length(name) > ?)
            SQL

            query.params.should eq([42, 3])
          end
        end

        context "without params" do
          it do
            query = Query(User).{{wherish.id}}(id: 42).or_{{wherish.id}}("name IS NOT NULL")

            query.to_s.should eq <<-SQL
            SELECT * FROM users {{wherish.upcase.id}} (id = ?) OR (name IS NOT NULL)
            SQL

            query.params.should eq([42])
          end
        end
      end
    end

    describe "#and" do
      context "after \#{{wherish.id}}" do
        it do
          query = Query(User).{{wherish.id}}(id: 42, name: !nil).and(role: User::Role::Admin)

          query.to_s.should eq <<-SQL
          SELECT * FROM users {{wherish.upcase.id}} (id = ? AND name IS NOT NULL) AND (role = ?)
          SQL

          query.params.should eq([42, 1])
        end
      end

      context "after #or_{{wherish.id}}" do
        it do
          query = Query(User).or_{{wherish.id}}(id: 42, name: nil).and(role: User::Role::Admin)

          query.to_s.should eq <<-SQL
          SELECT * FROM users {{wherish.upcase.id}} (role = ?) OR (id = ? AND name IS NULL)
          SQL

          query.params.should eq([1, 42])
        end
      end
    end

    describe "#or" do
      context "after \#{{wherish.id}}" do
        it do
          query = Query(User).{{wherish.id}}(id: 42).or(role: User::Role::Admin, name: nil)

          query.to_s.should eq <<-SQL
          SELECT * FROM users {{wherish.upcase.id}} (id = ?) OR (role = ? AND name IS NULL)
          SQL

          query.params.should eq([42, 1])
        end
      end

      context "after #or_{{wherish.id}}" do
        it do
          query = Query(User).or_{{wherish.id}}(id: 42, name: !nil).or(role: User::Role::Admin)

          query.to_s.should eq <<-SQL
          SELECT * FROM users {{wherish.upcase.id}} (id = ? AND name IS NOT NULL) OR (role = ?)
          SQL

          query.params.should eq([42, 1])
        end
      end
    end
  {% end %}
end
