require "./bench_helper"

puts "\nRunning Core::Logger benchmarks...\n".colorize(COLORS["header"])

def devnull
  File.open(File::DEVNULL, mode: "w")
end

logger = Logger.new(devnull, Logger::DEBUG)

elapsed = Time.measure do
  Benchmark.ips do |x|
    io = Core::Logger::IO.new(devnull)

    x.report "io w/  colors" do
      io.wrap("foo") { nil }
    end

    io = Core::Logger::IO.new(devnull, false)

    x.report "io w/o colors" do
      io.wrap("foo") { nil }
    end

    std_logger = Core::Logger::Standard.new(logger, Logger::Severity::INFO)

    x.report "logger w/  colors" do
      std_logger.wrap("foo") { nil }
    end

    std_logger = Core::Logger::Standard.new(logger, Logger::Severity::INFO, false)

    x.report "logger w/o colors" do
      std_logger.wrap("foo") { nil }
    end
  end
end

puts "\nCompleted in #{TimeFormat.auto(elapsed)} ✔️".colorize(COLORS["success"])
