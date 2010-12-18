require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'

spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "Maze generator for Ruby"
    s.name = 'theseus'
    s.version = "1.0.0"
    s.files = FileList["README.markdown", "Rakefile", "lib/**/*.rb", "bin/*"].to_a
    s.executables << "theseus"
    s.add_dependency "chunky_png", "~> 0.12.0"
    s.requirements << "Ruby 1.9"
    s.description = "Theseus is a library for building random mazes."
    s.author = "Jamis Buck"
    s.email = "jamis@jamisbuck.org"
    s.homepage = "http://github.com/jamis/theseus"
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
end
