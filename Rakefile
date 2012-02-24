# Source
require_relative 'src/metabuilder'

# Tests
require 'rake'
require 'rake/testtask'

task :default => [:test_units]

desc "Ejecutando los tests"
Rake::TestTask.new("test") { |t|
  t.pattern = 'test/test_*.rb'
  t.verbose = true
  t.warning = true
}
