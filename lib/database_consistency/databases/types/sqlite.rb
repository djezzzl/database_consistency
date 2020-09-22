# frozen_string_literal: true

module DatabaseConsistency
  module Databases
    module Types
      # Wraps types for SQLite database
      class Sqlite < Base
        TYPES = {
          'bigserial' => 'bigint',
          'bigint' => 'bigint',
          'serial' => 'integer',
          'integer' => 'integer'
        }.freeze

        # @return [String]
        def convert
          TYPES[type] || type
        end
      end
    end
  end
end
