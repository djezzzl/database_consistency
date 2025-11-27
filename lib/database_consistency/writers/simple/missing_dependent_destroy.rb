# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class MissingDependentDestroy < Base # :nodoc:
        private

        def template
          'needs an association with dependent destroy or delete'
        end

        def unique_attributes
          {
            model_name: report.model_name,
            attribute_name: report.attribute_name
          }
        end
      end
    end
  end
end
