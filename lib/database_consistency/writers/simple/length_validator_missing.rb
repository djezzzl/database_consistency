# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class LengthValidatorMissing < Base # :nodoc:
        private

        def template
          'column has a character length limit but does not have a length validator'
        end

        def unique_attributes
          {
            table_or_model_name: report.table_or_model_name,
            column_or_attribute_name: report.column_or_attribute_name
          }
        end
      end
    end
  end
end
