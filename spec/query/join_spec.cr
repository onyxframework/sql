require "../spec_helper"

require "../../src/core/schema"
require "../../src/core/query"

module QueryJoinSpec
  class User
    include Core::Schema
    include Core::Query

    schema :users do
      primary_key :id
      reference :referrer, User, key: :referrer_id
      reference :referrals, Array(User), foreign_key: :referrer_id
      reference :posts, Array(Post), foreign_key: :author_id
      field :name, String
      field :custom_field, String, key: :custom_key
    end
  end

  class Post
    include Core::Schema
    include Core::Query

    schema :posts do
      primary_key :id
      reference :author, User, key: :author_id
      reference :editor, User, key: :editor_id
    end
  end

  describe "#join" do
    context "with \"has_many\" reference" do
      it do
        sql = <<-SQL
          SELECT users.*, '' AS _posts, authored_posts.* FROM users JOIN posts AS "authored_posts" ON "authored_posts".author_id = users.id
        SQL

        User.join(:posts, as: :authored_posts).to_s.should eq(sql.strip)
      end
    end

    context "with \"belongs_to\" reference" do
      it do
        sql = <<-SQL
          SELECT posts.*, '' AS _author, author.* FROM posts JOIN users AS "author" ON "author".id = posts.author_id
        SQL

        Post.join(:author).to_s.should eq(sql.strip)
      end
    end

    context "with multiple calls" do
      it do
        sql = <<-SQL
          SELECT posts.*, '' AS _author, authors.*, '' AS _editor, editor.* FROM posts JOIN users AS "authors" ON "authors".id = posts.author_id JOIN users AS "editor" ON "editor".id = posts.editor_id
        SQL

        Post.join(:author, as: :authors).join(:editor).to_s.should eq(sql.strip)
      end
    end

    context "with self references" do
      context "\"has_many\"" do
        it do
          sql = <<-SQL
            SELECT users.*, '' AS _referrals, referrals.* FROM users JOIN users AS "referrals" ON "referrals".referrer_id = users.id
          SQL

          User.join(:referrals).to_s.should eq(sql.strip)
        end
      end

      context "\"belongs_to\"" do
        it do
          sql = <<-SQL
            SELECT users.*, '' AS _referrer, referrer.* FROM users JOIN users AS "referrer" ON "referrer".id = users.referrer_id
          SQL

          User.join(:referrer).to_s.should eq(sql.strip)
        end
      end
    end
  end

  describe "#inner_join" do
    it do
      User.inner_join(:posts).to_s.should contain("INNER JOIN")
    end
  end

  describe "select" do
    it "works with nil select" do
      sql = <<-SQL
        SELECT * FROM users JOIN users AS "referrer" ON "referrer".id = users.referrer_id
      SQL

      User.join(:referrer, select: nil).to_s.should eq(sql.strip)
    end

    it "works with single select" do
      sql = <<-SQL
        SELECT users.*, '' AS _referrer, referrer.id FROM users JOIN users AS "referrer" ON "referrer".id = users.referrer_id
      SQL

      User.join(:referrer, select: :id).to_s.should eq(sql.strip)
    end

    it "works with multiple select" do
      sql = <<-SQL
        SELECT users.*, '' AS _referrer, ref.id, ref.custom_key FROM users JOIN users AS "ref" ON "ref".id = users.referrer_id
      SQL

      User.join(:referrer, as: :ref, select: [:id, :custom_field]).to_s.should eq(sql.strip)
    end
  end

  {% for t in %i(left right full) %}
    describe "#" + {{t.id.stringify}} + "_join" do
      it do
        User.{{t.id}}_join(:posts).to_s.should contain("{{t.upcase.id}} JOIN")
      end
    end

    describe "#" + {{t.id.stringify}} + "_outer_join" do
      it do
        User.{{t.id}}_outer_join(:posts).to_s.should contain("{{t.upcase.id}} OUTER JOIN")
      end
    end
  {% end %}
end
