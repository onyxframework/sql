require "json"

# :nodoc:
module JSON::Serializable
  def to_db
    to_json.as(DB::Any | Array(DB::Any))
  end
end
