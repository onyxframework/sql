require "uri"

# :nodoc:
class URI
  def to_db
    to_s.as(DB::Any | Array(DB::Any))
  end
end
