require 'active_record'

require 'database_consistency/version'
require 'database_consistency/writers/base_writer'
require 'database_consistency/writers/simple_writer'
require 'database_consistency/comparison'
require 'database_consistency/helper'
require 'database_consistency/comparators/base_comparator'
require 'database_consistency/comparators/presence_comparator'
require 'database_consistency/processor'

# The root module
module DatabaseConsistency
  def self.run
    Helper.load_environment!

    Writers::SimpleWriter.write(
      Processor.new.comparisons,
      ENV['LOG_LEVEL'] || 'INFO'
    )
  end
end
