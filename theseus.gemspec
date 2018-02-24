$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'theseus/version'

Gem::Specification.new do |s|
  s.name        = 'theseus'
  s.version     = Theseus::Version::STRING
  s.authors     = ['Jamis Buck']
  s.email       = ['jamis@jamisbuck.org']
  s.license     = 'MIT'

  s.homepage    = 'https://github.com/jamis/theseus'
  s.summary     = 'Maze generator for Ruby'
  s.description = 'Theseus is a library for building random mazes.'

  s.files = Dir['README.rdoc', 'Rakefile', '{bin,lib,examples,test}/**/*']

  s.executables << 'theseus'

  s.add_dependency "chunky_png", "~> 1.3"
end
