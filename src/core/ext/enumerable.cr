require "uuid"
require "uri"

# :nodoc:
module Enumerable
  def to_db(t : Enumerable(UUID).class)
    map(&.to_s.as(DB::Any))
  end

  def to_db(t : Enumerable(Enum).class)
    map(&.to_s.underscore.as(DB::Any))
  end

  def to_db(t : Enumerable(URI).class)
    map(&.to_s.as(DB::Any))
  end

  def to_db(t : Enumerable(DB::Any).class)
    map(&.as(DB::Any))
  end
end
