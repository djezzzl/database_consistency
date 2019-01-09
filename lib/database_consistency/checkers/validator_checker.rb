# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # The base class for validator checker
    class ValidatorChecker < BaseChecker
      attr_reader :model, :attribute, :validator

      def initialize(model, attribute, validator)
        @model = model
        @attribute = attribute
        @validator = validator
      end
    end
  end
end
