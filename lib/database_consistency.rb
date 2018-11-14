require 'active_record'

require 'database_consistency/version'
require 'database_consistency/report'
require 'database_consistency/helper'
require 'database_consistency/configuration'

require 'database_consistency/writers/base_writer'
require 'database_consistency/writers/simple_writer'

require 'database_consistency/comparators/base_comparator'
require 'database_consistency/comparators/presence_comparator'
require 'database_consistency/validators_processor'

require 'database_consistency/column_verifiers/base_verifier'
require 'database_consistency/column_verifiers/presence_missing_verifier'
require 'database_consistency/database_processor'

# The root module
module DatabaseConsistency
  CONFIGURATION_PATH = '.database_consistency.yml'.freeze

  PROCESSORS = [
    ValidatorsProcessor,
    DatabaseProcessor
  ].freeze

  class << self
    def run
      Helper.load_environment!

      Writers::SimpleWriter.write(
        reports,
        ENV['LOG_LEVEL'] || 'INFO'
      )
    end

    def enabled_processors
      PROCESSORS.select { |processor| configuration.enabled?(processor) }
    end

    def reports
      enabled_processors.map(&:new).flat_map(&:reports)
    end

    def configuration
      @configuration ||= if File.exist?(CONFIGURATION_PATH)
                           Configuration.new(CONFIGURATION_PATH)
                         else
                           Configuration.new
                         end
    end
  end
end
