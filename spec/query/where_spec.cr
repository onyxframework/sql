require "../models"

describe "Atom::Query#where" do
  context "with explicit clause" do
    context "with params" do
      it do
        q = Atom::Query(User).new.where("foo = ? AND bar = ?", 42, [43, 44])

        q.to_s.should eq <<-SQL
        SELECT users.* FROM users WHERE (foo = ? AND bar = ?)
        SQL

        q.params.should eq [42, [43, 44]]
      end
    end

    context "without params" do
      it do
        q = Atom::Query(User).new.where("foo")

        q.to_s.should eq <<-SQL
        SELECT users.* FROM users WHERE (foo)
        SQL

        q.params.should eq nil
      end
    end
  end

  context "with attributes" do
    it do
      q = Atom::Query(User).new.where(active: true, name: "John")

      q.to_s.should eq <<-SQL
      SELECT users.* FROM users WHERE (users.activity_status = ? AND users.name = ?)
      SQL

      q.params.should eq [true, "John"]
    end
  end

  context "with references" do
    uuid = UUID.random

    it do
      q = Atom::Query(Post).new.where(author: User.new(uuid: uuid, name: "Jake"))

      q.to_s.should eq <<-SQL
      SELECT posts.* FROM posts WHERE (posts.author_uuid = ?)
      SQL

      q.params.should eq [uuid.to_s]
    end
  end

  describe "shorthands" do
    describe "#where_not" do
      context "with explicit clause" do
        context "without params" do
          it do
            Atom::Query(User).new.where_not("foo = 'bar'").to_s.should eq <<-SQL
            SELECT users.* FROM users WHERE NOT (foo = 'bar')
            SQL
          end
        end

        context "with params" do
          it do
            q = Atom::Query(User).new.where_not("foo = ?", 42)

            q.to_s.should eq <<-SQL
            SELECT users.* FROM users WHERE NOT (foo = ?)
            SQL

            q.params.should eq [42]
          end
        end
      end

      context "with named arguments" do
        it do
          q = Atom::Query(User).new.where_not(active: true, name: "John")

          q.to_s.should eq <<-SQL
          SELECT users.* FROM users WHERE NOT (users.activity_status = ? AND users.name = ?)
          SQL

          q.params.should eq [true, "John"]
        end
      end
    end

    describe "manually tested" do
      uuid = UUID.random

      it do
        q = Atom::Query(User).new.where(uuid: uuid).and_where("activity_status IS NOT NULL").and_not("name = ?", "John")

        q.to_s.should eq <<-SQL
        SELECT users.* FROM users WHERE (users.uuid = ?) AND (activity_status IS NOT NULL) AND NOT (name = ?)
        SQL

        q.params.should eq [uuid.to_s, "John"]
      end
    end

    # It has almost zero benefit for you as a reader, but it allows to check that all methods delegate their arguments as expected.
    #
    # Methods which are tested:
    #
    # - `#or_where_not`
    # - `#or_where`
    # - `#and_where_not`
    # - `#and_where`
    #
    # Each method has three variants (clause with params, single clause, named arguments) and two situations - when it's called for first time (e.g. `Query.new.and_where`) and when it's called afterwards (e.g. `Query.new.where.and_where`), which results in 24 tests. I decided that it would be simpler to use macros, which however require some skill to understand.
    {% for or in [true, false] %}
      {% for not in [true, false] %}
        describe '#' + {{(or ? "or" : "and")}} + "_where" do
          context "when first call" do
            context "with explicit clause" do
              context "without params" do
                it do
                  Atom::Query(User).new.{{(or ? "or" : "and").id}}_where{{"_not".id if not}}("foo = 'bar'").to_s.should eq <<-SQL
                  SELECT users.* FROM users WHERE {{"NOT ".id if not}}(foo = 'bar')
                  SQL
                end
              end

              context "with params" do
                it do
                  q = Atom::Query(User).new.{{(or ? "or" : "and").id}}_where{{"_not".id if not}}("foo = ?", 42)

                  q.to_s.should eq <<-SQL
                  SELECT users.* FROM users WHERE {{"NOT ".id if not}}(foo = ?)
                  SQL

                  q.params.should eq [42]
                end
              end

              context "with named arguments" do
                it do
                  q = Atom::Query(User).new.{{(or ? "or" : "and").id}}_where{{"_not".id if not}}(active: true, name: "John")

                  q.to_s.should eq <<-SQL
                  SELECT users.* FROM users WHERE {{"NOT ".id if not}}(users.activity_status = ? AND users.name = ?)
                  SQL

                  q.params.should eq [true, "John"]
                end
              end
            end
          end

          context "when non-first call" do
            context "with explicit clause" do
              context "without params" do
                it do
                  Atom::Query(User).new.where("first = true").{{(or ? "or" : "and").id}}_where{{"_not".id if not}}("foo = 'bar'").to_s.should eq <<-SQL
                  SELECT users.* FROM users WHERE (first = true) {{or ? "OR ".id : "AND ".id}}{{"NOT ".id if not}}(foo = 'bar')
                  SQL
                end
              end

              context "with params" do
                it do
                  q = Atom::Query(User).new.where("first = true").{{(or ? "or" : "and").id}}_where{{"_not".id if not}}("foo = ?", 42)

                  q.to_s.should eq <<-SQL
                  SELECT users.* FROM users WHERE (first = true) {{or ? "OR ".id : "AND ".id}}{{"NOT ".id if not}}(foo = ?)
                  SQL

                  q.params.should eq [42]
                end
              end
            end

            context "with named arguments" do
              it do
                q = Atom::Query(User).new.where("first = true").{{(or ? "or" : "and").id}}_where{{"_not".id if not}}(active: true, name: "John")

                q.to_s.should eq <<-SQL
                SELECT users.* FROM users WHERE (first = true) {{or ? "OR ".id : "AND ".id}}{{"NOT ".id if not}}(users.activity_status = ? AND users.name = ?)
                SQL

                q.params.should eq [true, "John"]
              end
            end
          end
        end
      {% end %}
    {% end %}
  end
end
