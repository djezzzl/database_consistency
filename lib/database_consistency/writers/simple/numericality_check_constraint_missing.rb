# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class NumericalityCheckConstraintMissing < Base # :nodoc:
        private

        def template
          'column has a numericality validator but does not have a CHECK constraint'
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
