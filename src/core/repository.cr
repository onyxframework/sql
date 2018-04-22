require "db"
require "./params"
require "./logger/dummy"
require "./repository/*"

# `Repository` is a gateway between `Model`s and Database.
#
# Supported methods:
#
# - `#query` (alias of `#query_all`)
# - `#query_one`
# - `#query_one?`
# - `#insert`
# - `#update`
# - `#delete`
# - `#exec`
# - `#scalar`
#
# See `Query` for a handy queries builder.
#
# ```
# logger = Core::Logger::IO.new(STDOUT)
# repo = Core::Repository.new(db, logger)
#
# user = User.new(name: "Foo")
# repo.insert(user) # TODO: [RFC] Return last inserted ID
# # INSERT INTO users (name, created_at) VALUES ($1, $2) RETURNING id
# # 1.773ms
#
# query = Query(User).last
# user = repo.query_one(query)
# # SELECT * FROM users ORDER BY id DESC LIMIT 1
# # 275μs
#
# user.name = "Bar"
# repo.update(user) # TODO: [RFC] Return a number of affected rows
# # UPDATE users SET name = $1 WHERE (id = $2) RETURNING id
# # 1.578ms
#
# repo.delete(user)
# # DELETE FROM users WHERE id = $1
# # 1.628ms
# ```
class Core::Repository
  # :nodoc:
  property db
  # :nodoc:
  property query_logger

  include Query
  include Insert
  include Update
  include Delete
  include Exec
  include Scalar

  # Initialize a new `Repository` istance linked to *db*,
  # which is data storage, and *query_logger*,
  # which logs Database queries.
  #
  # NOTE: *db* and *query_logger* can be changed in the runtime with according `#db=` and `#query_logger=` methods.
  def initialize(@db : ::DB::Database, @query_logger : Core::Logger = Core::Logger::Dummy.new)
  end

  # Prepare *query* for execution. Replaces "?" with "$i" for PostgreSQL.
  def prepare_query(query : String) : String
    if db.driver.is_a?(PG::Driver)
      counter = 0
      query = query.as(String).gsub("?") { "$" + (counter += 1).to_s }
    end

    query
  end

  private def now
    "NOW()"
  end
end
