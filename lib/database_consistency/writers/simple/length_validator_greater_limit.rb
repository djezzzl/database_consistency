# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class LengthValidatorGreaterLimit < Base # :nodoc:
        private

        def template
          'column character limit is greater than the length validator allows'
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
