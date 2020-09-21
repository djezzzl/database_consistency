# frozen_string_literal: true

module DatabaseConsistency
  module Databases
    module Types
      # Base wrapper for database types
      class Base
        attr_reader :type

        # @param [String] type
        def initialize(type)
          @type = type
        end

        # @return [String]
        def convert
          type
        end
      end
    end
  end
end
