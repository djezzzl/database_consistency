# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class PossibleNull < Base # :nodoc:
        private

        def template
          'column is NOT NULL but may receive a NULL value'
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
