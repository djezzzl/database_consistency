# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks missing presence validator
    class LengthConstraintChecker < ColumnChecker
      # Message templates
      VALIDATOR_MISSING = 'column has limit in the database but do not have length validator'
      GREATER_LIMIT = 'column has greater limit in the database than in length validator'
      LOWER_LIMIT = 'column has lower limit in the database than in length validator'

      VALIDATOR_CLASS =
        if defined?(ActiveRecord::Validations::LengthValidator)
          ActiveRecord::Validations::LengthValidator
        else
          ActiveModel::Validations::LengthValidator
        end

      private

      # We skip check when:
      #  - column hasn't limit constraint
      #  - column insn't string nor text
      def preconditions
        !column.limit.nil? && %i[string text].include?(column.type)
      end

      # Table of possible statuses
      # | validation | status  |
      # | ---------- | ------- |
      # | provided   | ok      |
      # | small      | warning |
      # | missing    | fail    |
      def check
        return report_template(:fail, VALIDATOR_MISSING) unless validator

        if valid?(:==)
          report_template(:ok)
        elsif valid?(:<)
          report_template(:warning, GREATER_LIMIT)
        else
          report_template(:fail, LOWER_LIMIT)
        end
      end

      def valid?(sign)
        %i[maximum is].each do |option|
          return validator.options[option].public_send(sign, column.limit) if validator.options[option]
        end

        false
      end

      def validator
        @validator ||= model.validators.grep(VALIDATOR_CLASS).find do |validator|
          Helper.check_inclusion?(validator.attributes, column.name)
        end
      end
    end
  end
end
