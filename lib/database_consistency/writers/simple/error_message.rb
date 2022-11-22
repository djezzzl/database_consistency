# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class ErrorMessage < Base # :nodoc:
        private

        def template
          report.error_message || ''
        end

        def unique_attributes
          report.to_h
        end
      end
    end
  end
end
