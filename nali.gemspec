# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nali/version'

Gem::Specification.new do |spec|
  spec.name          = 'nali'
  spec.version       = Nali::VERSION
  spec.authors       = ['4urbanoff']
  spec.email         = ['4urbanoff@gmail.com']
  spec.description   = 'Async web framework'
  spec.summary       = 'Framework for developing async web applications'
  spec.homepage      = 'https://github.com/4urbanoff/nali'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*', 'bin/**/*'] + ['LICENSE.txt', 'Rakefile', 'Gemfile', 'README.md']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_path  = 'lib'
  
  spec.bindir        = 'bin'
  spec.executables   = ['nali']
  
  spec.has_rdoc      = false
  
  spec.add_dependency 'thin'
  spec.add_dependency 'sinatra'
  spec.add_dependency 'sinatra-websocket'
  spec.add_dependency 'sinatra-activerecord'
  spec.add_dependency 'sinatra-reloader'
  spec.add_dependency 'sprockets'
  spec.add_dependency 'sprockets-sass'
  spec.add_dependency 'sprockets-helpers'
  spec.add_dependency 'coffee-script'
  spec.add_dependency 'sass'
  spec.add_dependency 'rake'
  
end
