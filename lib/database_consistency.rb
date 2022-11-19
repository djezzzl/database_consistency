# frozen_string_literal: true

require 'active_record'

require 'database_consistency/version'
require 'database_consistency/helper'
require 'database_consistency/configuration'
require 'database_consistency/rescue_error'
require 'database_consistency/errors'
require 'database_consistency/report'

require 'database_consistency/writers/base_writer'
require 'database_consistency/writers/todo_writer'

require 'database_consistency/writers/simple/base'
require 'database_consistency/writers/simple/error_message'
require 'database_consistency/writers/simple/inconsistent_types'
require 'database_consistency/writers/simple/null_constraint_association_misses_validator'
require 'database_consistency/writers/simple/redundant_index'
require 'database_consistency/writers/simple/redundant_unique_index'
require 'database_consistency/writers/simple/association_missing_index'
require 'database_consistency/writers/simple/association_missing_null_constraint'
require 'database_consistency/writers/simple/has_one_missing_unique_index'
require 'database_consistency/writers/simple/length_validator_lower_limit'
require 'database_consistency/writers/simple/length_validator_greater_limit'
require 'database_consistency/writers/simple/length_validator_missing'
require 'database_consistency/writers/simple/missing_foreign_key'
require 'database_consistency/writers/simple/missing_unique_index'
require 'database_consistency/writers/simple/missing_uniqueness_validation'
require 'database_consistency/writers/simple/null_constraint_misses_validator'
require 'database_consistency/writers/simple/null_constraint_missing'
require 'database_consistency/writers/simple/possible_null'
require 'database_consistency/writers/simple/small_primary_key'
require 'database_consistency/writers/simple_writer'

require 'database_consistency/writers/autofix/helpers/migration'
require 'database_consistency/writers/autofix/base'
require 'database_consistency/writers/autofix/migration_base'
require 'database_consistency/writers/autofix/missing_foreign_key'
require 'database_consistency/writers/autofix/inconsistent_types'
require 'database_consistency/writers/autofix/association_missing_index'
require 'database_consistency/writers/autofix/has_one_missing_unique_index'
require 'database_consistency/writers/autofix/redundant_index'
require 'database_consistency/writers/autofix/null_constraint_missing'
require 'database_consistency/writers/autofix_writer'

require 'database_consistency/databases/factory'
require 'database_consistency/databases/types/base'
require 'database_consistency/databases/types/sqlite'

require 'database_consistency/checkers/base_checker'

require 'database_consistency/checkers/association_checkers/association_checker'
require 'database_consistency/checkers/association_checkers/missing_index_checker'
require 'database_consistency/checkers/association_checkers/foreign_key_checker'
require 'database_consistency/checkers/association_checkers/foreign_key_type_checker'

require 'database_consistency/checkers/column_checkers/column_checker'
require 'database_consistency/checkers/column_checkers/null_constraint_checker'
require 'database_consistency/checkers/column_checkers/length_constraint_checker'
require 'database_consistency/checkers/column_checkers/primary_key_type_checker'

require 'database_consistency/checkers/validator_checkers/validator_checker'
require 'database_consistency/checkers/validator_checkers/missing_unique_index_checker'

require 'database_consistency/checkers/validators_fraction_checkers/validators_fraction_checker'
require 'database_consistency/checkers/validators_fraction_checkers/column_presence_checker'

require 'database_consistency/checkers/index_checkers/index_checker'
require 'database_consistency/checkers/index_checkers/unique_index_checker'
require 'database_consistency/checkers/index_checkers/redundant_index_checker'
require 'database_consistency/checkers/index_checkers/redundant_unique_index_checker'

require 'database_consistency/processors/base_processor'
require 'database_consistency/processors/associations_processor'
require 'database_consistency/processors/validators_processor'
require 'database_consistency/processors/columns_processor'
require 'database_consistency/processors/validators_fractions_processor'
require 'database_consistency/processors/indexes_processor'

# The root module
module DatabaseConsistency
  class << self
    def run(*args, **opts) # rubocop:disable Metrics/MethodLength
      configuration = Configuration.new(*args)
      reports = Processors.reports(configuration)

      if opts[:autofix]
        Writers::AutofixWriter.write(reports, config: configuration)

        0
      elsif opts[:todo]
        Writers::TodoWriter.write(reports, config: configuration)

        0
      else
        Writers::SimpleWriter.write(reports, config: configuration)

        reports.any? { |report| report.status == :fail } || !RescueError.empty? ? 1 : 0
      end
    end
  end
end
