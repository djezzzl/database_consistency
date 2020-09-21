# frozen_string_literal: true

require 'bundler/setup'
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

  config.include_context 'postgresql database context', :postgresql
  config.include_context 'mysql database context', :mysql
  config.include_context 'sqlite database context', :sqlite

  def file_fixture(path)
    File.join('spec/fixtures/files/', path)
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

  def test_each_database(databases = %i[sqlite mysql postgresql], &block)
    databases
      .map { |name| send("#{name}_configuration") }
      .each do |configuration|
        context "with #{configuration[:adapter]} database" do
          include_context 'database context', configuration
          instance_eval(&block)
        end
      end
  end
end
