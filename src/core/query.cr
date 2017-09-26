require "./query/*"

# `Query` allows to build database queries without a hassle.
#
# It heavily reliles on `Model::Schema#schema`, thus allowing to make queries like these:
#
# ```
# user = User.new(id: 42)
# query = Query(Post).where(author: user)
# query.to_s   # => SELECT * FROM posts WHERE author_id = ?
# query.params # => [42]
#
# query = Query(User).where(role: User::Role::Admin)
# query.to_s   # => SELECT * FROM users WHERE role = ?
# query.params # => [1]
# ```
#
# All queries are chainable:
#
# ```
# Query(User).where(id: 42).limit(1).to_s # => SELECT * FROM users WHERE id = ? LIMIT 1
# ```
#
# Queries can be built either after initialization or via class methods:
#
# ```
# # All equal
# Query(User).new.where(id: 42)
# Query(User).where(id: 42)
# Query.new(User).where(id: 42)
# Query.new(user).where(id: 42)
# ```
#
# For all examples below assume following mapping:
#
# ```
# class User < Core::Model
#   enum Role
#     User
#     Admin
#   end
#
#   schema do
#     primary_key :id
#     field :name, String
#     field :role, Role # INT in Database
#     reference :posts, Array(Post), foreign_key: :author_id
#     reference :edited_posts, Array(Post), foreign_key: :editor_id
#   end
# end
#
# class Post < Core::Model
#   schema do
#     primary_key :id
#     field :content, String
#     reference :author, User, key: :author_id, foreign_key: :id
#     reference :editor, User, key: :editor_id, foreign_key: :id
#   end
# end
# ```
struct Core::Query(ModelType)
  # TODO: Add `Enum`. See https://github.com/crystal-lang/crystal/issues/2733.
  alias DBValue = Bool | Float32 | Float64 | Int64 | Int32 | Int16 | String | Time | JSON::Any | Hash(String, String) | Nil

  # A list of params for this query.
  #
  # NOTE: `params` set for the first time only **after** `#to_s` call.
  getter params = [] of DBValue
  protected setter params

  def initialize(model_instance : ModelType? = nil)
  end

  def initialize(model_class : ModelType.class | Nil = nil)
  end

  # Reset all the values to defaults.
  #
  # FIXME: It's broken due to inability to include modules (see https://github.com/crystal-lang/crystal/issues/5023)
  def reset
    self
  end

  # Remove this query's `#limit` and return itself.
  #
  # ```
  # query = Query(User).new.limit(3).offset(5).all.to_s
  # # => SELECT * FROM users OFFSET 5
  # ```
  def all
    limit(nil)
    self
  end

  # Dummy method for convenience.
  #
  # ```
  # Query(User).all.to_s
  # # => SELECT * FROM users
  # ```
  def self.all
    self.new
  end

  # Sets this query limit to 1.
  #
  # ```
  # query = Query(User).new.one.to_s
  # # => SELECT * FROM users LIMIT 1
  # ```
  def one
    limit(1)
  end

  # :nodoc:
  def self.one
    self.new.one
  end

  # Query the last row by its `Model.primary_key`.
  #
  # ```
  # Query(User).new.last.to_s
  # # => SELECT * FROM users ORDER BY id DESC LIMIT 1
  # ```
  def last
    order_by(ModelType.primary_key, :DESC).one
  end

  # :nodoc:
  def self.last
    self.new.last
  end

  # Query the first row by its `Model.primary_key`.
  #
  # ```
  # Query(User).new.first.to_s
  # # => SELECT * FROM users ORDER BY id ASC LIMIT 1
  # ```
  def first
    order_by(ModelType.primary_key, :ASC).one
  end

  # :nodoc:
  def self.first
    self.new.first
  end

  # Build the query. Updates `#params`. Does not call `#reset`.
  def to_s
    params.clear

    query = ""
    select_clause
    from_clause
    join_clause
    where_clause
    group_by_clause
    having_clause
    order_by_clause
    limit_clause
    offset_clause

    query.strip
  end

  # :nodoc:
  macro from_clause
    query += " FROM " + ModelType.table_name
  end
end
