require "./logger/*"
require "./repository/*"

{% if @type.has_constant?("PG") %}
  module Core
    class Repository
      # :nodoc:
      PGDefined = true
    end
  end
{% end %}

module Core
  # A gateway between models and DB. Its main features are logging, expanding `Core::Query` instances and mapping models from resulting `DB::ResultSet`.
  #
  # ```
  # repo = Core::Repository.new(DB.open(ENV["DATABASE_URL"]), Core::Logger::IO.new(STDOUT))
  #
  # repo.scalar("SELECT 1").as(Int32)
  # # [postgresql] SELECT 1
  # # 593μs
  #
  # repo.scalar("SELECT ?::int", 1).as(Int32)
  # # ditto
  #
  # repo.query("SELECT * FROM users")       # Returns raw `DB::ResultSet`
  # repo.query(User, "SELECT * FROM users") # Returns `Array(User)`
  # repo.query(User.all)                    # Returns `Array(User)` as well
  # # [postgresql] SELECT users.* FROM users
  # # 442μs
  # # [map] User
  # # 101μs
  # ```
  class Repository
    # A `DB::Database` instance for this repository.
    property db

    # A `Core::Logger` instance for this repository.
    property logger

    # Initialize the repository.
    def initialize(@db : DB::Database, @logger : Core::Logger = Core::Logger::Dummy.new)
    end

    # Prepare query for initialization.
    #
    # If the `#db` driver is `PG::Driver`, replace all `?` with `$1`, `$2` etc. Otherwise return *sql_query* untouched.
    def prepare_query(sql_query : String)
      {% if @type.has_constant?("PGDefined") %}
        if db.driver.is_a?(PG::Driver)
          counter = 0
          sql_query = sql_query.gsub("?") { '$' + (counter += 1).to_s }
        end
      {% end %}

      sql_query
    end

    # Return `#db` driver name, e.g. `"postgresql"` for `PG::Driver`.
    def driver_name
      {% begin %}
        case db.driver
        {% if @type.has_constant?("PGDefined") %}
          when PG::Driver then "postgresql"
        {% end %}
        else "sql"
        end
      {% end %}
    end
  end
end
