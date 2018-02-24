require 'rake'
require 'rdoc/task'
require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = FileList["test/*.rb"]
  t.verbose = true
end

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
end

task :clean do
 rm_rf ["html", "pkg"]
end
