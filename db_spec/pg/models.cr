require "../../src/onyx-sql/converters/pg"
require "../../src/onyx-sql/converters/pg/uuid"
require "../../src/onyx-sql/converters/pg/json"
require "../../src/onyx-sql/converters/pg/jsonb"

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
    pkey uuid : UUID, converter: PG::UUID

    type active : Bool, key: "activity_status", default: true, not_null: true
    type role : Role, converter: PG::Enum(Role), default: true, not_null: true
    type permissions : Array(Permission), converter: PG::Enum(Permission), default: true, not_null: true
    type favorite_numbers : Array(Int32), converter: PG::Any(Int32), default: true, not_null: true
    type name : String, not_null: true
    type balance : Float32, default: true, not_null: true
    type meta : Meta, converter: PG::JSON(User::Meta), default: true, not_null: true
    type created_at : Time, default: true, not_null: true
    type updated_at : Time

    type referrer : User, key: "referrer_uuid"
    type referrals : Array(User), foreign_key: "referrer_uuid"
    type authored_posts : Array(Post), foreign_key: "author_uuid"
    type edited_posts : Array(Post), foreign_key: "editor_uuid"
  end
end

class Tag
  include Model

  schema tags do
    pkey id : Int32, converter: PG::Any(Int32)
    type content : String, not_null: true
    type posts : Array(Post), foreign_key: "tag_ids"
  end
end

class Post
  include Model

  record Meta, meta : Hash(String, String)? do
    include JSON::Serializable
  end

  schema posts do
    pkey id : Int32, converter: PG::Any(Int32)

    type content : String, not_null: true
    type cover : Bytes
    type meta : Meta, converter: PG::JSONB(Meta), default: true
    type created_at : Time, default: true, not_null: true
    type updated_at : Time

    type author : User, key: "author_uuid", not_null: true
    type editor : User, key: "editor_uuid"
    type tags : Array(Tag), key: "tag_ids"
  end
end
