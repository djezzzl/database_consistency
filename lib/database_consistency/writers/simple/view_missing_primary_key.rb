# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class ViewMissingPrimaryKey < Base # :nodoc:
        private

        def template
          'model backed by a database view should have primary_key set'
        end

        def unique_attributes
          {
            table_or_model_name: report.table_or_model_name
          }
        end
      end
    end
  end
end
