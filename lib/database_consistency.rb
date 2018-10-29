require 'active_record'

require 'database_consistency/version'
require 'database_consistency/formatters/simple_formatter'
require 'database_consistency/comparison'
require 'database_consistency/helper'
require 'database_consistency/comparators/base_comparator'
require 'database_consistency/comparators/presence_comparator'
require 'database_consistency/processor'

# The root module
module DatabaseConsistency
end
