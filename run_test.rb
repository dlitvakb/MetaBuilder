# Tests
require 'rake'
require 'rake/testtask'

task :default => [:test]

Rake::TestTask.new("test") { |t|
  t.pattern = 'test/test_*.rb'
}
