require 'rake'
require 'rubygems/package_task'
require 'rdoc/task'
require 'rake/testtask'

require './lib/theseus/version'

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = FileList["test/*.rb"]
  t.verbose = true
end

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.summary = "Maze generator for Ruby"
  s.name = 'theseus'
  s.version = Theseus::Version::STRING
  s.files = FileList["README.rdoc", "Rakefile", "lib/**/*.rb", "examples/**/*.rb", "bin/*", "test/**/*.rb"].to_a
  s.executables << "theseus"
  s.add_dependency "chunky_png", "~> 0.12.0"
  s.requirements << "Ruby 1.9"
  s.description = "Theseus is a library for building random mazes."
  s.author = "Jamis Buck"
  s.email = "jamis@jamisbuck.org"
  s.homepage = "http://github.com/jamis/theseus"
end

Rake::PackageTask.new('theseus', Theseus::Version::STRING) do |pkg|
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

task :clean do
 rm_rf ["html", "pkg"]
end
