# frozen_string_literal: true

require 'active_record'

require 'database_consistency/version'
require 'database_consistency/helper'
require 'database_consistency/configuration'

require 'database_consistency/writers/base_writer'
require 'database_consistency/writers/simple_writer'

require 'database_consistency/checkers/base_checker'
require 'database_consistency/checkers/table_checker'
require 'database_consistency/checkers/validator_checker'
require 'database_consistency/checkers/column_presence_checker'
require 'database_consistency/checkers/null_constraint_checker'
require 'database_consistency/checkers/belongs_to_presence_checker'

require 'database_consistency/processors/base_processor'
require 'database_consistency/processors/models_processor'
require 'database_consistency/processors/tables_processor'

# The root module
module DatabaseConsistency
  class << self
    def run
      Helper.load_environment!

      configuration = Configuration.new
      reports = Processors.reports(configuration)

      Writers::SimpleWriter.write(
        reports,
        ENV['LOG_LEVEL'] || 'INFO'
      )

      reports.empty? ? 0 : 1
    end
  end
end
