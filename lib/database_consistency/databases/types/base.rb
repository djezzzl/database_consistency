# frozen_string_literal: true

module DatabaseConsistency
  module Databases
    module Types
      # Base wrapper for database types
      class Base
        attr_reader :type

        COVERED_TYPES = {
          'bigint' => %w[integer bigint],
          'integer' => %w[integer smallint]
        }

        # @param [String] type
        def initialize(type)
          @type = type
        end

        # @return [String]
        def convert
          type
        end

        # @param [DatabaseConsistency::Databases::Types::Base]
        #
        # @return [Boolean]
        def cover?(other_type)
          p 'AAA'
          p convert
          p other_type.convert
          p 'GGG'

          (COVERED_TYPES[convert] || [convert]).include?(other_type.convert)
        end
      end
    end
  end
end
