# frozen_string_literal: true

require 'active_record'

require 'database_consistency/version'
require 'database_consistency/helper'
require 'database_consistency/configuration'
require 'database_consistency/rescue_error'

require 'database_consistency/writers/base_writer'
require 'database_consistency/writers/simple_writer'

require 'database_consistency/checkers/base_checker'
require 'database_consistency/checkers/association_checker'
require 'database_consistency/checkers/column_checker'
require 'database_consistency/checkers/validator_checker'

require 'database_consistency/checkers/column_presence_checker'
require 'database_consistency/checkers/null_constraint_checker'
require 'database_consistency/checkers/belongs_to_presence_checker'
require 'database_consistency/checkers/missing_unique_index_checker'
require 'database_consistency/checkers/missing_index_checker'

require 'database_consistency/processors/base_processor'
require 'database_consistency/processors/associations_processor'
require 'database_consistency/processors/validators_processor'
require 'database_consistency/processors/columns_processor'

# The root module
module DatabaseConsistency
  class << self
    def run
      configuration = Configuration.new
      reports = Processors.reports(configuration)

      Writers::SimpleWriter.write(
        reports,
        config: configuration
      )

      reports.any? { |report| report.status == :fail } ? 1 : 0
    end
  end
end
