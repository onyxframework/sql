require "./spec_helper"

enum Database
  Postgresql
end

def repo(database : Database)
  Atom::Repository.new(DB.open(ENV["#{database.to_s.upcase}_URL"]), Atom::Repository::Logger::IO.new(STDOUT))
end
