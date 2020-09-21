# frozen_string_literal: true

require 'active_record'

require 'database_consistency/version'
require 'database_consistency/helper'
require 'database_consistency/configuration'
require 'database_consistency/rescue_error'

require 'database_consistency/writers/base_writer'
require 'database_consistency/writers/simple_writer'

require 'database_consistency/databases/factory'
require 'database_consistency/databases/types/base'
require 'database_consistency/databases/types/sqlite'

require 'database_consistency/checkers/base_checker'

require 'database_consistency/checkers/association_checkers/association_checker'
require 'database_consistency/checkers/association_checkers/missing_index_checker'
require 'database_consistency/checkers/association_checkers/foreign_key_type_checker'

require 'database_consistency/checkers/column_checkers/column_checker'
require 'database_consistency/checkers/column_checkers/null_constraint_checker'
require 'database_consistency/checkers/column_checkers/length_constraint_checker'
require 'database_consistency/checkers/column_checkers/primary_key_type_checker'

require 'database_consistency/checkers/validator_checkers/validator_checker'
require 'database_consistency/checkers/validator_checkers/belongs_to_presence_checker'
require 'database_consistency/checkers/validator_checkers/missing_unique_index_checker'

require 'database_consistency/checkers/validators_fraction_checkers/validators_fraction_checker'
require 'database_consistency/checkers/validators_fraction_checkers/column_presence_checker'

require 'database_consistency/processors/base_processor'
require 'database_consistency/processors/associations_processor'
require 'database_consistency/processors/validators_processor'
require 'database_consistency/processors/columns_processor'
require 'database_consistency/processors/validators_fractions_processor'

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

      reports.any? { |report| report.status == :fail } || !RescueError.empty? ? 1 : 0
    end
  end
end
