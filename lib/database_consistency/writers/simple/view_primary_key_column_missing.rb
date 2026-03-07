# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class ViewPrimaryKeyColumnMissing < Base # :nodoc:
        private

        def template
          'model backed by a database view has primary_key set to a non-existent column'
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
