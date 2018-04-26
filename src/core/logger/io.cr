require "time_format"
require "colorize"

require "../logger"

# Logs queries into IO.
class Core::Logger::IO < Core::Logger
  def initialize(@io : ::IO)
  end

  # Wrap a query, logging elaped time.
  #
  # ```
  # wrap("SELECT * FROM users") do |q|
  #   db.query(q)
  # end
  # # => SELECT * FROM users
  # # => 501μs
  # ```
  def wrap(query : String, &block : String -> _)
    log_query(query)
    started_at = Time.now
    r = yield(query)
    log_time(Time.now - started_at)
    r
  end

  protected def log_query(query)
    @io << "\n" + query.colorize(:blue).to_s + "\n"
  end

  protected def log_time(elapsed : Time::Span)
    @io << TimeFormat.auto(elapsed).colorize(:magenta).to_s + "\n"
  end
end
