require "./spec_helper"

class User
  include Atom::Model

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
    pkey uuid : UUID
    type referrer : Union(User | Nil), key: "referrer_uuid"

    type active : Bool = DB::Default, key: "activity_status"
    type role : Role = DB::Default
    type permissions : Array(Permission) = DB::Default
    type name : String
    type balance : Float32 = DB::Default
    type meta : Meta = DB::Default

    type created_at : Time = DB::Default
    type updated_at : Union(Time, Nil)

    type referrals : Array(User), foreign_key: "referrer_uuid"
    type authored_posts : Array(Post), foreign_key: "author_uuid"
    type edited_posts : Array(Post), foreign_key: "editor_uuid"
  end
end

class Tag
  include Atom::Model

  schema tags do
    pkey id : Int32
    type content : String
    type posts : Array(Post), foreign_key: "tag_ids"
  end
end

class Post
  include Atom::Model

  schema posts do
    pkey id : Int32
    type author : User, key: "author_uuid"
    type editor : Union(User, Nil), key: "editor_uuid"
    type tags : Array(Tag) = DB::Default, key: "tag_ids"

    type content : String
    type created_at : Time = DB::Default
    type updated_at : Union(Time | Nil)
  end
end
