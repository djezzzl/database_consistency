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

  def file_fixture(path)
    File.join('spec/fixtures/files/', path)
  end

  def test_each_database(&block)
    [
      { adapter: 'sqlite3', database: ':memory:' },
      { adapter: 'mysql2', database: 'database_consistency_test' },
      { adapter: 'postgresql', database: 'database_consistency_test' }
    ].each do |configuration|
      context "with #{configuration[:adapter]} database" do
        include_context 'database context', configuration
        instance_eval(&block)
      end
    end
  end
end
