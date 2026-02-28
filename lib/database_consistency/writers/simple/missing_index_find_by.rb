# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class MissingIndexFindBy < Base # :nodoc:
        private

        def template
          'column is used in find_by but is missing an index%<source_location>s'
        end

        def attributes
          { source_location: report.source_location ? " (found at #{report.source_location})" : '' }
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
