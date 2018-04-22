require "./spec_helper"

require "../src/core/schema"
require "../src/core/query"

alias Query = Core::Query

module QuerySpec
  class User
    include Core::Schema

    enum Role
      User
      Admin
    end

    schema :users do
      primary_key :id
      field :name, String
      field :role, Role, converter: Core::Converters::Enum
    end
  end

  describe Core::Query do
    pending "returns new instance every time a method is called" do
      q1 = Query(User).new
      q2 = q1.select(:foo)
      q1.select_values.should eq [:*]
    end

    describe "#reset" do
      pending do
        query = Query(User).select(:*).order_by(:id).where("char_length(name) > ?", [1]).limit(3).offset(5).join(:posts).group_by(:"users.id", :"posts.id").having("COUNT (posts.id) > ?", [1])

        query.reset.to_s.should eq <<-SQL
        SELECT * FROM users
        SQL
      end
    end

    describe "#clone" do
      query = Query(User).select(:id).order_by(:id).where("char_length(name) > ?", [1]).limit(3).offset(5)
      cloned_query = query.clone

      it "creates identical object" do
        query.should eq cloned_query
      end

      # It's a Struct, so #object_id is unnaceptable here (see https://crystal-lang.org/api/master/Reference.html#object_id%3AUInt64-instance-method, it says "The returned value is the memory address of this object.")
      # #hash doesn't work too.
      pending "has object with different identificator" do
      end

      it "preserves clauses" do
        cloned_query.to_s.should eq query.to_s
      end

      it "creates object which references another inner objects" do
        query.select(:name)
        cloned_query.select_values.should eq [:id]
        query.limit(10)
        cloned_query.limit_value.should eq 3
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

    describe "#and" do
      context "after \#where" do
        it do
          query = Query(User).where(id: 42, name: !nil).and(role: User::Role::Admin)

          query.to_s.should eq <<-SQL
          SELECT * FROM users WHERE (users.id = ? AND users.name IS NOT NULL) AND (users.role = ?)
          SQL

          query.params.should eq([42, 1])
        end
      end

      context "after #or_where" do
        it do
          query = Query(User).where(id: 43).or_where(id: 42, name: nil).and(role: User::Role::Admin)

          query.to_s.should eq <<-SQL
          SELECT * FROM users WHERE (users.id = ?) AND (users.role = ?) OR (users.id = ? AND users.name IS NULL)
          SQL

          query.params.should eq([43, 1, 42])
        end
      end
    end

    describe "#or" do
      context "after \#where" do
        it do
          query = Query(User).where(id: 42).or(role: User::Role::Admin, name: nil)

          query.to_s.should eq <<-SQL
          SELECT * FROM users WHERE (users.id = ?) OR (users.role = ? AND users.name IS NULL)
          SQL

          query.params.should eq([42, 1])
        end
      end

      context "after #or_where" do
        it do
          query = Query(User).or_where(id: 42, name: !nil).or(role: User::Role::Admin)

          query.to_s.should eq <<-SQL
          SELECT * FROM users WHERE (users.id = ? AND users.name IS NOT NULL) OR (users.role = ?)
          SQL

          query.params.should eq([42, 1])
        end
      end
    end

    describe "complex #and & #or" do
      it do
        query = Query(User).where(id: [42, 43, 44]).having("char_length(name) > ?", [3]).and(role: User::Role::Admin).and_where(name: nil).or("id > ?", [24])

        query.to_s.should eq <<-SQL
        SELECT * FROM users WHERE (users.id IN (?, ?, ?)) AND (users.name IS NULL) OR (id > ?) HAVING (char_length(name) > ?) AND (users.role = ?)
        SQL

        query.params.should eq([42, 43, 44, 24, 3, 1])
      end
    end
  end
end
