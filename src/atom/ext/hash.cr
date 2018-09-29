# :nodoc:
class Hash(K, V)
  def to_db
    to_json.as(DB::Any | Array(DB::Any))
  end
end
