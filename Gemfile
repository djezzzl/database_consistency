# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in database_consistency.gemspec
gemspec

local_gemfile = 'Gemfile.local'

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
else
  gem 'activerecord', ENV.fetch('AR_VERSION', '> 7')
  gem 'mysql2', ENV.fetch('MYSQL_VERSION', '~> 0.5')
  gem 'pg', ENV.fetch('PG_VERSION', '~> 0.2')
  gem 'sqlite3', ENV.fetch('SQLITE_VERSION', '~> 1.3')
end
