# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'database_consistency/version'

Gem::Specification.new do |spec|
  spec.name          = 'database_consistency'
  spec.version       = DatabaseConsistency::VERSION
  spec.authors       = ['Evgeniy Demin']
  spec.email         = ['lawliet.djez@gmail.com']

  spec.summary       = 'Provide an easy way to check the consistency of the '\
                        'database constraints with the application validations.'
  spec.homepage      = 'https://github.com/djezzzl/database_consistency'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']
  spec.executables   = ['database_consistency']

  spec.required_ruby_version = '>= 2.4.0'

  spec.add_dependency 'activerecord', '>= 3.2'

  spec.add_development_dependency 'bundler', '> 1.16'
  spec.add_development_dependency 'mysql2', '~> 0.5'
  spec.add_development_dependency 'pg', '~> 0.2'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.55'
  spec.add_development_dependency 'sqlite3', '~> 1.3'
end
