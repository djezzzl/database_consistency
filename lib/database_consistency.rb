require 'active_record'

require 'database_consistency/version'
require 'database_consistency/report'
require 'database_consistency/helper'

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
  def self.run
    Helper.load_environment!

    reports = [
      ValidatorsProcessor.new,
      DatabaseProcessor.new
    ].flat_map(&:reports)

    Writers::SimpleWriter.write(
      reports,
      ENV['LOG_LEVEL'] || 'INFO'
    )
  end
end
