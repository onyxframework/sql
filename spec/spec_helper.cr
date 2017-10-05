require "spec"
require "../src/core"

alias Query = Core::Query
alias Repo = Core::Repository

class User < Core::Model
  enum Role
    User
    Admin
  end

  schema do
    table_name "users"
    primary_key :id
    field :role, Role, default: Role::User
    field :name, String
    created_at_field :created_at, json_converter: Converters::JSON::TimeEpoch
    updated_at_field :updated_at, json_converter: Converters::JSON::TimeEpoch
    reference :referrer, User, key: :referrer_id, foreign_key: :id
    reference :referrals, Array(User), foreign_key: :referrer_id
    reference :posts, Array(Post), foreign_key: :author_id
    reference :edited_posts, Array(Post), foreign_key: :editor_id
    virtual_field :posts_count, Int32 | Int64
  end

  validation do
    errors.push({:name => "length must be > 3"}) unless name.try &.size.> 3
  end
end

class Post < Core::Model
  schema do
    table_name "posts"
    primary_key :id
    field :content, String
    reference :author, User, key: :author_id
    reference :editor, User, key: :editor_id
    created_at_field :created_at
    updated_at_field :updated_at
  end
end
