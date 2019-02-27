require "./spec_helper"
require "./dummy_converters/*"

require "uuid"
require "json"

alias Model = Onyx::SQL::Model
alias Field = Onyx::SQL::Field

@[Model::Options(table: "users", primary_key: @uuid)]
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
    pkey uuid : UUID, converter: DummyConverters::UUID

    type active : Bool, key: "activity_status", default: true
    type role : Role, converter: DummyConverters::Enum(Role), default: true
    type permissions : Array(Permission), converter: DummyConverters::Enum(Permission), default: true
    type favorite_numbers : Array(Int32), converter: DummyConverters::Int32Array, default: true
    type name : String, not_null: true
    type balance : Float32, default: true
    type meta : Meta, converter: DummyConverters::JSON(Meta), default: true
    type created_at : Time, default: true
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
    pkey id : Int32
    type content : String
    type posts : Array(Post), foreign_key: "tag_ids"
  end
end

class Post
  include Model

  schema posts do
    pkey id : Int32, converter: DummyConverters::Int32Array

    type content : String
    type created_at : Time, default: true
    type updated_at : Time

    type author : User, key: "author_uuid"
    type editor : User, key: "editor_uuid"
    type tags : Array(Tag), key: "tag_ids"
  end
end
