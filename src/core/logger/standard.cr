require "logger"
require "colorize"
require "time_format"
require "../logger"

# Logs queries into standard `::Logger` at debug level.
class Core::Logger::Standard < Core::Logger
  def initialize(@logger : ::Logger)
  end

  # Wrap a query, logging elaped time at debug level.
  #
  # ```
  # wrap("SELECT * FROM users") do |q|
  #   db.query(q)
  # end
  # # [21:54:51:068] DEBUG > SELECT * FROM users
  # # [21:54:51:068] DEBUG > 501μs
  # ```
  def wrap(query : String, &block : String -> _)
    log_query(query)
    started_at = Time.now
    r = yield(query)
    log_time(Time.now - started_at)
    r
  end

  protected def log_query(query)
    @logger.debug(query.colorize(:blue))
  end

  protected def log_time(elapsed : Time::Span)
    @logger.debug(TimeFormat.auto(elapsed).colorize(:magenta))
  end
end
