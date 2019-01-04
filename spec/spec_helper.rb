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
end
