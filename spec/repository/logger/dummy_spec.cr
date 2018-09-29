require "../../spec_helper"

describe Atom::Repository::Logger::Dummy do
  it do
    logger = Atom::Repository::Logger::Dummy.new
    logger.wrap("foo") { "bar" }.should eq "bar"
  end
end
