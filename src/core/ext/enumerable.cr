require "uuid"
require "uri"

# :nodoc:
module Enumerable
  def to_db(t : Enumerable(UUID).class)
    to_a.map(&.to_s.as(DB::Any))
  end

  def to_db(t : Enumerable(Enum).class)
    to_a.map(&.to_s.underscore.as(DB::Any))
  end

  def to_db(t : Enumerable(URI).class)
    to_a.map(&.to_s.as(DB::Any))
  end

  def to_db(t : Enumerable(DB::Any).class)
    to_a.map(&.as(DB::Any))
  end
end
