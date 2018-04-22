require "./converter"
require "./query/*"

# `Query` allows to build database queries without a hassle.
#
# It heavily reliles on `Model::Schema#schema`, thus allowing to make powerful queries like these:
#
# ```
# user = User.new(id: 42)
#
# # Yay, references!
# query = Query(Post).where(author: user)
# query.to_s   # => SELECT * FROM posts WHERE author_id = ?
# query.params # => [42]
#
# # Yay, plain enums!
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
# Queries can be created either after initialization or via class methods:
#
# ```
# # All equal
# Query(User).new.where(id: 42)
# Query(User).where(id: 42)
# Query.new(User).where(id: 42)
# Query.new(user).where(id: 42)
# ```
#
# You can pass Query as argument to `Repository#query`. It will automatically build the query (`#to_s`) and extract its `#params`:
#
# ```
# users = repo.query(Query(User).all.limit(3))
# ```
#
# And of course, you can use Query in plain Database methods:
#
# ```
# query = Query(User).select(:"COUNT(id)").where("char_length(name) > ?", [3])
# count = db.scalar(query.to_s, query.params).as(Int64)
# # SELECT COUNT(id) FROM users WHERE char_length(name) > ?
# count # => 2
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
  # A list of params for this query.
  #
  # NOTE: `params` set for the first time only **after** `#to_s` call.
  getter params = [] of ::DB::Any
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

  # TODO: Split to modules. Currently impossible due to https://github.com/crystal-lang/crystal/issues/5023
  def clone
    clone = self.class.new
    clone.group_by_values = self.group_by_values.dup
    clone.having_values = self.having_values.clone
    clone.or_having_values = self.or_having_values.clone
    clone.join_values = self.join_values.dup
    clone.limit_value = self.limit_value
    clone.offset_value = self.offset_value
    clone.order_by_values = self.order_by_values.dup
    clone.select_values = self.select_values.dup
    clone.where_values = self.where_values.clone
    clone.or_where_values = self.or_where_values.clone
    return clone
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

  # Query the last row by `Model::Schema.primary_key[:name]`.
  #
  # ```
  # Query(User).new.last.to_s
  # # => SELECT * FROM users ORDER BY id DESC LIMIT 1
  # ```
  def last
    order_by(ModelType.primary_key[:name], :DESC).one
  end

  # :nodoc:
  def self.last
    self.new.last
  end

  # Query the first row by `Model::Schema.primary_key[:name]`.
  #
  # ```
  # Query(User).new.first.to_s
  # # => SELECT * FROM users ORDER BY id ASC LIMIT 1
  # ```
  def first
    order_by(ModelType.primary_key[:name], :ASC).one
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
    query += " FROM " + {{ModelType::TABLE.id.stringify}}
  end

  @last_wherish_clause = :where

  {% for x in %w(and or) %}
    # A shorthand for calling `{{x.id}}_where` or `{{x.id}}_having` depending on the last clause call.
    #
    # ```
    # query.where(foo: "bar").{{x.id}}(baz: "qux")
    # # => WHERE (foo = 'bar') {{x.upcase.id}} (baz = 'qux')
    # query.having(foo: "bar").{{x.id}}(baz: "qux")
    # # => HAVING (foo = 'bar') {{x.upcase.id}} (baz = 'qux')
    # ```
    def {{x.id}}(**args)
      case @last_wherish_clause
      when :having
        {{x.id}}_having(**args)
      else
        {{x.id}}_where(**args)
      end
    end

    # A shorthand for calling `{{x.id}}_where` or `{{x.id}}_having` depending on the last clause call.
    #
    # ```
    # query.where(foo: "bar").{{x.id}}("created_at > NOW()")
    # # => WHERE (foo = 'bar') {{x.upcase.id}} (created_at > NOW())
    # query.having(foo: "bar").{{x.id}}("created_at > NOW()")
    # # => HAVING (foo = 'bar') {{x.upcase.id}} (created_at > NOW())
    # ```
    def {{x.id}}(clause, params = nil)
      case @last_wherish_clause
      when :having
        {{x.id}}_having(clause, params)
      else
        {{x.id}}_where(clause, params)
      end
    end
  {% end %}
end
