require "../spec_helper"
require "../../src/core/logger/io"

describe Core::Logger::IO do
  it do
    io = IO::Memory.new
    logger = Core::Logger::IO.new(io, false)
    logger.wrap("foo") { "bar" }.should eq "bar"
    io.to_s.should match %r{foo\n.+s\n}
  end
end
