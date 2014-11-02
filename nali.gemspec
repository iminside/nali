# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nali/version'

Gem::Specification.new do |s|
  s.name          = 'nali'
  s.version       = Nali::VERSION
  s.authors       = ['4urbanoff']
  s.email         = ['4urbanoff@gmail.com']
  s.description   = 'Async web framework'
  s.summary       = 'Framework for developing async web applications'
  s.homepage      = 'https://github.com/4urbanoff/nali'
  s.license       = 'MIT'

  s.files         = Dir['lib/**/*', 'bin/**/*'] + ['LICENSE.txt', 'Rakefile', 'Gemfile', 'README.md']
  s.require_path  = 'lib'
  
  s.bindir        = 'bin'
  s.executables   = ['nali']
  
  s.has_rdoc      = false
  
  s.add_dependency 'thin',                 '>= 1.6'
  s.add_dependency 'rake',                 '~> 10.3'
  s.add_dependency 'sinatra',              '>= 1.4'
  s.add_dependency 'sinatra-websocket',    '~> 0.3'
  s.add_dependency 'sinatra-activerecord', '~> 2.0'
  s.add_dependency 'sinatra-reloader',     '~> 1.0'
  s.add_dependency 'sprockets',            '~> 2.0'
  s.add_dependency 'sprockets-sass',       '~> 1.2'
  s.add_dependency 'sprockets-helpers',    '~> 1.1'
  s.add_dependency 'coffee-script',        '~> 2.3'
  s.add_dependency 'sass',                 '~> 3.4'
  
end
