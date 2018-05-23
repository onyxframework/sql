require "logger"
require "colorize"
require "time_format"
require "../logger"

# Logs queries into standard `::Logger`.
class Core::Logger::Standard < Core::Logger
  def initialize(@logger : ::Logger)
  end

  # Wrap a query, logging elaped time.
  #
  # ```
  # wrap("SELECT * FROM users") do |q|
  #   db.query(q)
  # end
  # # => [21:54:51:068]  INFO > SELECT * FROM users
  # # => [21:54:51:068]  INFO > 501μs
  # ```
  def wrap(query : String, &block : String -> _)
    log_query(query)
    started_at = Time.now
    r = yield(query)
    log_time(Time.now - started_at)
    r
  end

  protected def log_query(query)
    @logger.info(query.colorize(:blue))
  end

  protected def log_time(elapsed : Time::Span)
    @logger.info(TimeFormat.auto(elapsed).colorize(:magenta))
  end
end
