require "time_format"
require "colorize"

# Logs queries.
class Core::QueryLogger
  def initialize(@io : IO?)
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
  def wrap(query, &block)
    log_query(query)
    started_at = Time.now
    r = yield(query)
    log_time(Time.now - started_at)
    r
  end

  protected def log_query(query)
    return unless @io
    @io.not_nil! << "\n" + query.colorize(:blue).to_s + "\n"
  end

  protected def log_time(elapsed : Time::Span)
    return unless @io
    @io.not_nil! << TimeFormat.auto(elapsed).colorize(:magenta).to_s + "\n"
  end
end
