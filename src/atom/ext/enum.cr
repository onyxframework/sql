# :nodoc:
struct Enum
  def to_db
    to_s.underscore.as(DB::Any | Array(DB::Any))
  end
end
