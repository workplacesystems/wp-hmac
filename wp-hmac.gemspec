# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wp/hmac/version'

Gem::Specification.new do |spec|
  spec.name          = 'wp-hmac'
  spec.version       = Wp::Hmac::VERSION
  spec.authors       = ['Andrew Nagi']
  spec.email         = ['andrew.nagi@gmail.com']
  spec.summary       = 'HMAC for Rack Apps'
  spec.description   =
    'Enable different HMAC keys on different routes / subdomains.'
  spec.homepage      = 'https://github.com/workplacesystems/wp-hmac'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_dependency 'ey_api_hmac', '0.4.12'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rails', '4.1.4'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.29'
  spec.add_development_dependency 'fuubar', '~> 2.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'sqlite3'
end
