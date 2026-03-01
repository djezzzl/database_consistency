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
          if report.source_location
            count = report.total_findings_count || 1
            count_str = count > 1 ? ", and #{count - 1} more occurrences" : ''
            { source_location: " (found at #{report.source_location}#{count_str})" }
          else
            { source_location: '' }
          end
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
