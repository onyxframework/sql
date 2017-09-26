require "../query_spec"

describe Query do
  describe "#join" do
    context "with \"has_many\" reference" do
      it do
        sql = <<-SQL
          SELECT * FROM users JOIN posts AS authored_posts ON authored_posts.author_id = users.id
        SQL

        Query(User).join(:posts, on: :author, as: :authored_posts).to_s.should eq(sql.strip)
      end
    end

    context "with \"belongs_to\" reference" do
      it do
        sql = <<-SQL
          SELECT * FROM posts JOIN users AS author ON author.id = posts.author_id
        SQL

        Query(Post).join(:author).to_s.should eq(sql.strip)
      end
    end

    context "with multiple calls" do
      it do
        sql = <<-SQL
          SELECT * FROM posts JOIN users AS authors ON authors.id = posts.author_id JOIN users AS editor ON editor.id = posts.editor_id
        SQL

        Query(Post).join(:author, as: :authors).join(:editor).to_s.should eq(sql.strip)
      end
    end

    context "with self references" do
      context "\"has_many\"" do
        it do
          sql = <<-SQL
            SELECT * FROM users JOIN users AS referrals ON referrals.referrer_id = users.id
          SQL

          Query(User).join(:referrals).to_s.should eq(sql.strip)
        end
      end

      context "\"belongs_to\"" do
        it do
          sql = <<-SQL
            SELECT * FROM users JOIN users AS referrer ON referrer.id = users.referrer_id
          SQL

          Query(User).join(:referrer).to_s.should eq(sql.strip)
        end
      end
    end
  end

  describe "#inner_join" do
    it do
      Query(User).inner_join(:posts).to_s.should contain("INNER JOIN")
    end
  end

  {% for t in %i(left right full) %}
    describe "#" + {{t.id.stringify}} + "_join" do
      it do
        Query(User).{{t.id}}_join(:posts).to_s.should contain("{{t.upcase.id}} JOIN")
      end
    end

    describe "#" + {{t.id.stringify}} + "_outer_join" do
      it do
        Query(User).{{t.id}}_outer_join(:posts).to_s.should contain("{{t.upcase.id}} OUTER JOIN")
      end
    end
  {% end %}
end
