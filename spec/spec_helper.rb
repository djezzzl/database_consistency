# frozen_string_literal: true

require 'bundler/setup'
require 'logger'
require 'database_consistency'
require 'database_context'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  case ENV['DATABASE']
  when 'mysql'
    config.inclusion_filter.add(mysql: true)
    config.include_context 'mysql database context'
  when 'postgresql'
    config.inclusion_filter.add(postgresql: true)
    config.include_context 'postgresql database context'
  else
    config.inclusion_filter.add(sqlite: true)
    config.include_context 'sqlite database context'
  end

  def file_fixture(path)
    File.join('spec/fixtures/files/', path)
  end

  def adapter
    if ActiveRecord::Base.respond_to?(:connection_config)
      ActiveRecord::Base.connection_config[:adapter]
    else
      ActiveRecord::Base.connection_db_config.configuration_hash[:adapter]
    end
  end

  def mysql_configuration
    {
      adapter: 'mysql2',
      database: 'database_consistency_test',
      host: ENV['DB_HOST'] || '127.0.0.1',
      username: ENV['DB_USER'],
      password: ENV['DB_PASSWORD']
    }
  end

  def sqlite_configuration
    {
      adapter: 'sqlite3',
      database: ':memory:'
    }
  end

  def postgresql_configuration
    {
      adapter: 'postgresql',
      database: 'database_consistency_test',
      host: ENV['DB_HOST'] || '127.0.0.1',
      username: ENV['DB_USER'],
      password: ENV['DB_PASSWORD']
    }
  end
end
