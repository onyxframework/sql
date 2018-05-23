require "./spec_helper"

require "../src/core/schema"
require "../src/core/query"
require "../src/core/converters/enum"

alias Query = Core::Query

module QuerySpec
  class User
    include Core::Schema
    include Core::Query

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
    describe "#reset" do
      it do
        query = Query.new(User).order_by(:id).where("char_length(name) > ?", [1]).limit(3).offset(5).group_by("users.id", "posts.id").having("COUNT (posts.id) > ?", [1])

        query.reset.to_s.should eq <<-SQL
        SELECT users.* FROM users
        SQL
      end
    end

    describe "#clone" do
      query = User.select(:id).order_by(:id).where("char_length(name) > ?", [1]).limit(3).offset(5)
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
        query.reset
        cloned_query.to_s.should eq <<-SQL
        SELECT id FROM users WHERE (char_length(name) > ?) ORDER BY id LIMIT 3 OFFSET 5
        SQL
        cloned_query.params.should eq [1]
      end
    end

    describe "#update" do
      it do
        query = User.update.where(id: 3)
        query.to_s.should eq <<-SQL
        UPDATE users WHERE (users.id = ?)
        SQL
      end
    end

    describe "#delete" do
      it do
        query = User.delete.where(id: 3)
        query.to_s.should eq <<-SQL
        DELETE FROM users WHERE (users.id = ?)
        SQL
      end
    end

    describe "#all" do
      it do
        query = User.limit(3).offset(5)
        query.all.to_s.should eq <<-SQL
        SELECT users.* FROM users OFFSET 5
        SQL
      end
    end

    describe "#one" do
      it do
        User.one.to_s.should eq <<-SQL
        SELECT users.* FROM users LIMIT 1
        SQL
      end
    end

    describe "#last" do
      it do
        User.last.to_s.should eq <<-SQL
        SELECT users.* FROM users ORDER BY id DESC LIMIT 1
        SQL
      end
    end

    describe "#first" do
      it do
        User.first.to_s.should eq <<-SQL
        SELECT users.* FROM users ORDER BY id ASC LIMIT 1
        SQL
      end
    end

    describe "#and" do
      context "after \#where" do
        it do
          query = User.where(id: 42, name: !nil).and(role: User::Role::Admin)

          query.to_s.should eq <<-SQL
          SELECT users.* FROM users WHERE (users.id = ? AND users.name IS NOT NULL) AND (users.role = ?)
          SQL

          query.params.should eq([42, 1])
        end
      end

      context "after #or_where" do
        it do
          query = User.where(id: 43).or_where(id: 42, name: nil).and(role: User::Role::Admin)

          query.to_s.should eq <<-SQL
          SELECT users.* FROM users WHERE (users.id = ?) OR (users.id = ? AND users.name IS NULL) AND (users.role = ?)
          SQL

          query.params.should eq([43, 42, 1])
        end
      end
    end

    describe "#and_not" do
      it do
        query = User.where(id: 42, name: !nil).and_not(role: User::Role::Admin)

        query.to_s.should eq <<-SQL
        SELECT users.* FROM users WHERE (users.id = ? AND users.name IS NOT NULL) AND NOT (users.role = ?)
        SQL

        query.params.should eq([42, 1])
      end
    end

    describe "#or" do
      context "after \#where" do
        it do
          query = User.where(id: 42).or(role: User::Role::Admin, name: nil)

          query.to_s.should eq <<-SQL
          SELECT users.* FROM users WHERE (users.id = ?) OR (users.role = ? AND users.name IS NULL)
          SQL

          query.params.should eq([42, 1])
        end
      end

      context "after #or_where" do
        it do
          query = User.or_where(id: 42, name: !nil).or(role: User::Role::Admin)

          query.to_s.should eq <<-SQL
          SELECT users.* FROM users WHERE (users.id = ? AND users.name IS NOT NULL) OR (users.role = ?)
          SQL

          query.params.should eq([42, 1])
        end
      end
    end

    describe "#or_not" do
      it do
        query = User.having(id: 42).or_not(role: User::Role::Admin, name: nil)

        query.to_s.should eq <<-SQL
        SELECT users.* FROM users HAVING (users.id = ?) OR NOT (users.role = ? AND users.name IS NULL)
        SQL

        query.params.should eq([42, 1])
      end
    end

    describe "complex #and & #or" do
      it do
        query = User.where(id: [42, 43, 44]).having("char_length(name) > ?", [3]).and(role: User::Role::Admin).and_where(name: nil).or("id > ?", [24]).and_not(name: "john")

        query.to_s.should eq <<-SQL
        SELECT users.* FROM users WHERE (users.id IN (?, ?, ?)) AND (users.name IS NULL) OR (id > ?) AND NOT (users.name = ?) HAVING (char_length(name) > ?) AND (users.role = ?)
        SQL

        query.params.should eq([42, 43, 44, 24, "john", 3, 1])
      end
    end
  end
end
