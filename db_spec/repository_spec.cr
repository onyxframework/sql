require "./spec_helper"

enum Database
  Postgresql
end

def repo(database : Database)
  Core::Repository.new(DB.open(ENV["#{database.to_s.upcase}_URL"]), Core::Logger::IO.new(STDOUT))
end
