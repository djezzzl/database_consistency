# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class ErrorMessage < Base # :nodoc:
        private

        def template
          report.error_message || ''
        end
      end
    end
  end
end
