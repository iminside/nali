# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nali/version'

Gem::Specification.new do |spec|
  spec.name          = "nali"
  spec.version       = Nali::VERSION
  spec.authors       = ["4urbanoff"]
  spec.email         = ["4urbanoff@gmail.com"]
  spec.description   = "Realtime app"
  spec.summary       = "summary"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + ["LICENSE.txt", "Rakefile", "Gemfile", "README.md"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "thin"
  spec.add_dependency "sinatra"
  spec.add_dependency "sinatra-websocket"
  spec.add_dependency "sinatra-activerecord"
  spec.add_dependency "sinatra-reloader"
  spec.add_dependency "sprockets"
  spec.add_dependency "sprockets-sass"
  spec.add_dependency "sprockets-helpers"
  spec.add_dependency "coffee-script"
  spec.add_dependency "sass"
  spec.add_dependency "sqlite3"
  
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
