require "../../spec_helper"

describe Atom::Repository::Logger::IO do
  it do
    io = IO::Memory.new
    logger = Atom::Repository::Logger::IO.new(io, false)
    logger.wrap("foo") { "bar" }.should eq "bar"
    io.to_s.should match %r{foo\n.+s\n}
  end
end
