require "../../src/onyx-sql/converters/sqlite3"
require "../../src/onyx-sql/converters/sqlite3/json"

alias Model = Onyx::SQL::Model
alias Field = Onyx::SQL::Field

class User
  include Model

  enum Role
    Writer
    Moderator
    Admin
  end

  enum Permission
    CreatePosts
    EditPosts
  end

  struct Meta
    include JSON::Serializable
    property foo : String?

    def initialize(@foo = nil)
    end
  end

  schema users do
    pkey id : Int32, key: "rowid", converter: SQLite3::Any(Int32)

    type active : Bool, key: "activity_status", default: true, not_null: true
    type role : Role, converter: SQLite3::EnumInt(Role), default: true, not_null: true
    type permissions : Array(Permission), converter: SQLite3::EnumText(Permission), default: true, not_null: true
    type favorite_numbers : Array(Int32), converter: SQLite3::Any(Int32), default: true, not_null: true
    type name : String, not_null: true
    type balance : Float32, default: true, not_null: true
    type meta : Meta, converter: SQLite3::JSON(User::Meta), default: true, not_null: true
    type created_at : Time, default: true, not_null: true
    type updated_at : Time

    type referrer : User, key: "referrer_id"
    type referrals : Array(User), foreign_key: "referrer_id"
    type authored_posts : Array(Post), foreign_key: "author_id"
    type edited_posts : Array(Post), foreign_key: "editor_id"
  end
end

class Tag
  include Model

  schema tags do
    pkey id : Int32, converter: SQLite3::Any(Int32), key: "rowid"
    type content : String, not_null: true
    type posts : Array(Post), foreign_key: "tag_ids"
  end
end

class Post
  include Model

  schema posts do
    pkey id : Int32, converter: SQLite3::Any(Int32), key: "rowid"

    type content : String, not_null: true
    type created_at : Time, default: true, not_null: true
    type updated_at : Time

    type author : User, key: "author_id", not_null: true
    type editor : User, key: "editor_id"
    type tags : Array(Tag), key: "tag_ids"
  end
end
