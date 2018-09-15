require "../spec_helper"
require "../../src/core/logger/dummy"

describe Core::Logger::Dummy do
  it do
    logger = Core::Logger::Dummy.new
    logger.wrap("foo") { "bar" }.should eq "bar"
  end
end
